from PIL import Image
from transformers import CLIPProcessor, CLIPModel
import torch


MODEL_NAME = "openai/clip-vit-base-patch32"


print("Loading CLIP model...")


model = CLIPModel.from_pretrained(
    MODEL_NAME,
    local_files_only=False
)


processor = CLIPProcessor.from_pretrained(
    MODEL_NAME,
    local_files_only=False
)


model.eval()


print("CLIP loaded successfully")


def generate_image_embedding(image_file):

    image = Image.open(
        image_file
    ).convert(
        "RGB"
    )

    inputs = processor(
        images=image,
        return_tensors="pt"
    )

    with torch.no_grad():

        vision_outputs = model.vision_model(
            pixel_values=inputs["pixel_values"]
        )

        pooled_output = vision_outputs.pooler_output

        image_features = model.visual_projection(
            pooled_output
        )

    print(
        "Embedding shape:",
        image_features.shape
    )

    image_features = (
        image_features /
        image_features.norm(
            p=2,
            dim=-1,
            keepdim=True
        )
    )

    return image_features[0].cpu().numpy()
