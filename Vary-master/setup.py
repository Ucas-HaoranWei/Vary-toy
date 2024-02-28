from setuptools import setup, find_packages

setup(
    name='vary',
    version='0.1.0',
    packages=find_packages(),
    install_requires=[
        "einops", "markdown2[all]", "numpy",
        "requests", "sentencepiece", "tokenizers>=0.12.1",
        "torch", "torchvision", "wandb",
        "shortuuid", "httpx==0.24.0",
        "deepspeed==0.12.3",
        "peft==0.4.0",
        "albumentations ",
        "opencv-python",
        "tiktoken",
        "accelerate==0.24.1",
        "transformers==4.32.1",
        "bitsandbytes==0.41.0",
        "scikit-learn==1.2.2",
        "sentencepiece==0.1.99",
        "einops==0.6.1", "einops-exts==0.0.4", "timm==0.6.13",
        "gradio_client==0.2.9",
        "fastapi>=0.110.0",
        "uvicorn>=0.27.1",
        "python-multipart>=0.0.9",
    ],
)
