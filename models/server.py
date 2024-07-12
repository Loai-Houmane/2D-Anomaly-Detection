import io
from flask import Flask, request, send_file
from PIL import Image
import torch
from torchvision import transforms
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_agg import FigureCanvasAgg
from .CDO import CDOModel  # Ensure this import works in your environment

# Initialize the model
device = torch.device("cpu")
h, w = 256, 256
gamma = 2
OOM = True
backbone = 'hrnet32'
kwargs = {'out_size_h': h, 'out_size_w': w, 'device': device, 'gamma': gamma, 'OOM': OOM, 'backbone': backbone}
model = CDOModel(**kwargs).to(device)
model.load('models/carpet.pt')
model.eval()
print("Model loaded")

def process_image(image):
    preprocess = transforms.Compose([
        transforms.Resize((h, w)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
    input_tensor = preprocess(image)
    input_batch = input_tensor.unsqueeze(0).to(device)

    with torch.no_grad():
        output = model(input_batch)
        anomaly_maps = model.cal_am(FE=output['FE'], FA=output['FA'])
    anomaly_map = np.array(anomaly_maps[0])
    anomaly_map = (anomaly_map - anomaly_map.min()) / (anomaly_map.max() - anomaly_map.min())

    fig = plt.figure(figsize=(4, 4))
    plt.imshow(anomaly_map, cmap='jet')
    plt.axis('off')
    plt.tight_layout(pad=0)  # Adjust padding around the figure

    canvas = FigureCanvasAgg(fig)
    canvas.draw()
    img_arr = np.array(canvas.buffer_rgba())
    img = Image.fromarray(img_arr, 'RGBA')
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='PNG')
    img_byte_arr = img_byte_arr.getvalue()
    return img_byte_arr

app = Flask(__name__)

@app.route('/anomaly', methods=['POST'])
def anomaly():
    file = request.files['file']
    image = Image.open(file.stream)
    img_byte_arr = process_image(image)
    return send_file(io.BytesIO(img_byte_arr), mimetype='image/png')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)