<h3><a href="">Small Language Model Meets with Reinforced Vision Vocabulary</a></h3>
<a href="https://varytoy.github.io/"><img src="https://img.shields.io/badge/Project-Page-Green"></a>
<a href="https://arxiv.org/abs/2401.12503"><img src="https://img.shields.io/badge/Paper-PDF-orange"></a> 
<a href="https://vary.xiaomy.net/"><img src="https://img.shields.io/badge/demo-blue"></a> 
<a href="https://zhuanlan.zhihu.com/p/679447793"><img src="https://img.shields.io/badge/zhihu-yellow"></a> 


[Haoran Wei*](https://scholar.google.com/citations?user=J4naK0MAAAAJ&hl=en), Lingyu Kong*, Jinyue Chen, Liang Zhao, [Zheng Ge](https://joker316701882.github.io/), [En Yu](https://scholar.google.com.hk/citations?user=rWCQMNgAAAAJ&hl=zh-CN&oi=sra), [Jianjian Sun](https://scholar.google.com/citations?user=MVZrGkYAAAAJ&hl=en), Chunrui Han, [Xiangyu Zhang](https://scholar.google.com/citations?user=yuB-cfoAAAAJ&hl=en)

<p align="center">
<img src="assets/vary-toy-logo.jpg" style="width: 200px" align=center>
</p>

<p align="center">
<a href="">The Young's First ``Large'' Vision Language Model</a>       
</p>


## Release
- [2024/7/21] 🎉🎉🎉 OneChart is accepted by ACM'MM 2024 **Oral**! (3.97%)
- [2024/7/2] 🔥🔥🔥 Vary is accepted by ECCV2024. To thank everyone for their attention, I will release a model that performs on par with the Vary-document soon.
- [2024/5/27] 🔥🔥🔥 We present a document understanding benchmark in [Fox](https://github.com/ucaslcl/Fox) .
- [2024/5/24] 🔥🔥🔥 We propose a multi-page document understanding work -- [Fox](https://arxiv.org/abs/2405.14295), which supports 8-page pdf-image input !!!
- [2024/4/21] 🔥🔥🔥 For OneChart, we have released the web demo in [Project Page](https://onechartt.github.io/). Have fun!!
- [2024/4/21] 🔥🔥🔥 We present a Vary-tiny LAVIS codebase (for training from scratch) and the Vary-600k dataset (300K English and 300K Chinese pages) [here](https://github.com/Ucas-HaoranWei/Vary-tiny-600k) !!!
- [2024/4/15]🔥🔥🔥We release a chart parsing model OneChart [here](https://github.com/LingyvKong/OneChart).
- [2024/4/12]🔥🔥🔥We will release a chart parsing model based on Vary-tiny next week. The model supports both English and Chinese charts.
- [2024/3/16]🔥🔥🔥I found many friends very interested in Vary-tiny(OPT-125M), so I opened source it [here](https://huggingface.co/HaoranWei/Vary-tiny-opt125M/tree/main), a PDF-dense OCR and object detection version.
- [2024/1/23] 🔥Eval codes will be available soon.
- [2024/1/23] 🔥🔥🔥You only need a single 1080Ti to experience all features of current LVLMs.




[![Code License](https://img.shields.io/badge/Code%20License-Apache_2.0-green.svg)](https://github.com/tatsu-lab/stanford_alpaca/blob/main/LICENSE)
[![Data License](https://img.shields.io/badge/Data%20License-CC%20By%20NC%204.0-red.svg)](https://github.com/tatsu-lab/stanford_alpaca/blob/main/DATA_LICENSE)
**Usage and License Notices**: The data, code, and checkpoint are intended and licensed for research use only. They are also restricted to use that follow the license agreement of LLaMA, Vicuna, GPT-4, Qwen, and LLaVA. 


## Contents
- [Install](#install)
- [Vary-toy Weights](#vary-weights)
- [Demo](#Demo)
- [Train](#train)

## Note
If you have built the original [Vary](https://github.com/Ucas-HaoranWei/Vary), please rebuild this repo !!!

## Install

1. Clone this repository and navigate to the Vary folder
```bash
git clone https://github.com/Ucas-HaoranWei/Vary-toy.git
cd /path/to/vary-toy
```
2. Install Package
```Shell
conda create -n vary python=3.10 -y
conda activate vary
pip install e .
```

3. Install Flash-Attention
```
pip install ninja
pip install flash-attn --no-build-isolation
```

## Vary Weights
- Download the Vary-toy weights [here](https://huggingface.co/Haoran-megvii/Vary-toy). 
- Download the CLIP-VIT-L [here](https://huggingface.co/openai/clip-vit-large-patch14/).



## Demo
1. Update the CLIP-VIT path in the codes (/cache/vit-large-patch14/) to your path.

2.
```Shell
python vary/demo/run_qwen_vary.py  --model-name  /vary/model/path/ --image-file /an/image/file.png
```
## Train
```Shell
deepspeed   Vary/train/train_qwen_vary.py  --deepspeed /Vary/zero_config/zero2.json
            --model_name_or_path /Vary-toy/path/
            --vision_tower /vit-large-patch14/path/
            --freeze_vision_tower True
            --freeze_lm_model False
            --vision_select_layer  -2
            --use_im_start_end True
            --bf16 True
            --per_device_eval_batch_size 4
            --gradient_accumulation_steps 1
            --evaluation_strategy "no"
            --save_strategy "steps"
            --save_steps 5000
            --save_total_limit 1
            --weight_decay 0.
            --warmup_ratio 0.03
            --lr_scheduler_type "cosine"
            --logging_steps 1 --tf32 True
            --model_max_length 4096
            --gradient_checkpointing True
            --dataloader_num_workers 4
            --report_to none
            --per_device_train_batch_size 4
            --num_train_epochs 1
            --learning_rate 5e-5
            --datasets  data_name1+data_name2+data_name3
            --output_dir /path/to/output/
```
We encourage you to extract the new vision vocabulary weights for your new base language model !!!

## Contact
If you have any questions about the code or the paper, please email (`weihaoran18@mails.ucas.ac.cn`).

## Discussion
Vary-toy is not a toy, and we have designed two excellent models based on it, one is Vary-document (specifically for document/pdf processing), and the other is Vary-plot for chart analysis.  You can see their amazing performance here [Vary-family](https://github.com/Ucas-HaoranWei/Vary-family). 

## Citation
If you find our work useful in your research, please consider citing Vary:
```bibtex
@article{wei2023vary,
  title={Vary: Scaling up the Vision Vocabulary for Large Vision-Language Models},
  author={Wei, Haoran and Kong, Lingyu and Chen, Jinyue and Zhao, Liang and Ge, Zheng and Yang, Jinrong and Sun, Jianjian and Han, Chunrui and Zhang, Xiangyu},
  journal={arXiv preprint arXiv:2312.06109},
  year={2023}
}

@article{wei2024small,
  title={Small Language Model Meets with Reinforced Vision Vocabulary},
  author={Wei, Haoran and Kong, Lingyu and Chen, Jinyue and Zhao, Liang and Ge, Zheng and Yu, En and Sun, Jianjian and Han, Chunrui and Zhang, Xiangyu},
  journal={arXiv preprint arXiv:2401.12503},
  year={2024}
}
```

