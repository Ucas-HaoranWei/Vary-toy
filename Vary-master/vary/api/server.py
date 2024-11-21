from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
from PIL import Image
import io
import os
from os import getenv
from dataclasses import dataclass
from typing import Optional
import torch
from transformers import AutoTokenizer, CLIPImageProcessor, TextStreamer
from vary.model import varyQwenForCausalLM
from vary.model.plug.blip_process import BlipImageEvalProcessor
from vary.utils.conversation import conv_templates, SeparatorStyle
from vary.utils.utils import KeywordsStoppingCriteria, disable_torch_init
from torchvision.transforms import functional as F
import argparse
import warnings
warnings.filterwarnings("ignore", category=UserWarning)

app = FastAPI()

# 允许跨域请求
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@dataclass
class Config:
    """
    Configuration class to manage default settings and environment variables.
    """
    model_name: str = getenv('MODEL_NAME', '/app/Vary-master/Varyweight')
    conv_mode: str = "mpt"
    clip_model_path: str = getenv('CLIP_MODEL_PATH', '/app/Vary-master/clip-vit-large-patch14')
    max_new_tokens: int = 4096 # default value: 2048
    image_token_len: int = 256 # default value: 256
    im_start_token: str = "<img>"
    im_end_token: str = "</img>"
    image_patch_token: str = "<imgpad>"


# 默认参数
DEFAULT_MODEL_NAME = Config().model_name
DEFAULT_CONV_MODE = Config().conv_mode
CLIP_MODEL_PATH = Config().clip_model_path
MAX_NEW_TOKENS = Config().max_new_tokens
IMAGE_TOKEN_LEN = Config().image_token_len
DEFAULT_IM_START_TOKEN = Config().im_start_token
DEFAULT_IM_END_TOKEN = Config().im_end_token
DEFAULT_IMAGE_PATCH_TOKEN = Config().image_patch_token

# 说明注释示例
# IMAGE_TOKEN_LEN: 用于定义图像编码的令牌长度。调整此参数可能会影响模型性能和兼容性。
# 重要: 修改 IMAGE_TOKEN_LEN 可能需要调整模型的结构或重新训练，以确保模型能正确处理新的令牌长度。

# 验证Token的模型和函数
class Token(BaseModel):
    token: Optional[str] = None

def validate_token(token: str):
    return token == "secret-token"

@app.post("/eval-image/")
async def eval_image(token: str = Form(...), file: UploadFile = File(...)):
    if not validate_token(token):
        raise HTTPException(status_code=400, detail="Invalid or expired token.")
    
    image_bytes = await file.read()
    image = Image.open(io.BytesIO(image_bytes)).convert('RGB')

    result = eval_model(image=image)
    
    return {"result": result}

def eval_model(image: Image, model_name: str = DEFAULT_MODEL_NAME, conv_mode: str = DEFAULT_CONV_MODE):
    disable_torch_init()

    # 定义图像开始、结束和补丁标记

    use_im_start_end = True
    image_token_len = IMAGE_TOKEN_LEN

    # Load tokenizer and model with appropriate data types
    tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
    model = varyQwenForCausalLM.from_pretrained(model_name, low_cpu_mem_usage=True, device_map='cuda', trust_remote_code=True)
    model.to(device='cuda', dtype=torch.bfloat16)  # Ensure model is in the correct data type

    # Process image with appropriate data type
    image_processor = CLIPImageProcessor.from_pretrained(CLIP_MODEL_PATH, torch_dtype=torch.float16)
    image_processor_high = BlipImageEvalProcessor(image_size=1024)

    qs = 'Provide the OCR results of this image.'
    if use_im_start_end:
        qs = DEFAULT_IM_START_TOKEN + DEFAULT_IMAGE_PATCH_TOKEN*image_token_len + DEFAULT_IM_END_TOKEN + '\n' + qs
    else:
        qs = DEFAULT_IMAGE_PATCH_TOKEN + '\n' + qs

    conv = conv_templates[conv_mode].copy()
    conv.append_message(conv.roles[0], qs)
    conv.append_message(conv.roles[1], None)
    prompt = conv.get_prompt()

    inputs = tokenizer([prompt])
    
    image_1 = image.copy()

    image_tensor = image_processor.preprocess(image, return_tensors='pt')['pixel_values'][0]
    image_tensor_1 = image_processor_high(image_1)

    input_ids = torch.as_tensor(inputs.input_ids).cuda()

    # stop_str = conv.sep if conv.sep_style != SeparatorStyle.TWO else conv.sep2
    stop_str = conv.sep if conv.sep_style != SeparatorStyle.TWO else conv.sep2
    keywords = [stop_str]
    stopping_criteria = KeywordsStoppingCriteria(keywords, tokenizer, input_ids)
    streamer = TextStreamer(tokenizer, skip_prompt=True, skip_special_tokens=True)

    with torch.autocast("cuda", dtype=torch.bfloat16):
        output_ids = model.generate(
            input_ids,
            images=[(image_tensor.unsqueeze(0).half().cuda(), image_tensor_1.unsqueeze(0).half().cuda())],
            do_sample=True,
            num_beams=1,
            # temperature=0.2,
            streamer=streamer,
            max_new_tokens=MAX_NEW_TOKENS,
            stopping_criteria=[stopping_criteria]
        )

    outputs = tokenizer.decode(output_ids[0, input_ids.shape[1]:]).strip()
    return outputs
