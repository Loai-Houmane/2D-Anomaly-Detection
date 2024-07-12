import tkinter as tk
from tkinter import PhotoImage, filedialog
from PIL import Image, ImageTk
import torch
from torchvision import transforms
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_agg import FigureCanvasAgg
from .CDO import CDOModel  # Ensure this import works in your environment

# Initialize the model (Step 2)
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

class AnomalyDetectionApp:
    def __init__(self, master):
        self.master = master
        master.title("Anomaly Detection")
        # Assuming the original image size is larger than 300x300 and you want to resize it to fit within a 300 width frame
        # without cutting the image. This example uses a fixed subsample rate for simplicity.
        
        # Load the logo image with a subsample to resize it proportionally
        # The subsample rate (e.g., 2) needs to be determined based on the original and desired image size
        subsample_rate = 3  # Example subsample rate, adjust based on your needs
        self.logo_image = PhotoImage(file="ADL.png").subsample(subsample_rate, subsample_rate)
        
        # Create a label for the logo image
        self.logo_label = tk.Label(master, image=self.logo_image)
        self.logo_label.pack()
  # Prevent the label from resizing to fit the image
        # Layout (Step 3)
        self.select_image_btn = tk.Button(master, text="Select Image", command=self.select_image)
        self.select_image_btn.pack()

        self.image_label = tk.Label(master)
        self.image_label.pack()

        self.anomaly_map_label = tk.Label(master)
        self.anomaly_map_label.pack()

    def select_image(self):
        # Function to select an image (Step 4)
        file_path = filedialog.askopenfilename()
        if file_path:
            self.image = Image.open(file_path)
            self.display_image(self.image, self.image_label)
            self.process_image(self.image)

    def process_image(self, image):
        # Function to process the image (Step 5)
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
        
        # Get original image size
        orig_width, orig_height = image.size

        # Calculate aspect ratio and adjust figsize accordingly
        aspect_ratio = orig_width / orig_height
        fig_width = 2.55  # Fixed width for the figure
        fig_height = fig_width / aspect_ratio  # Calculate height based on the aspect ratio
        # Adjust figsize to match the aspect ratio of the anomaly map and remove padding
        fig = plt.figure(figsize=(fig_width,fig_height), dpi=100)  # Adjust dpi as needed
        plt.imshow(anomaly_map, cmap='jet')
        plt.axis('off')  # Hide the axis
        plt.subplots_adjust(left=0, right=1, top=1, bottom=0)  # Remove padding around the figure
    
        # Convert matplotlib figure to a format that Tkinter Label can display
        canvas = FigureCanvasAgg(fig)
        canvas.draw()
        tk_image = ImageTk.PhotoImage(image=Image.fromarray(np.array(canvas.buffer_rgba())))
    
        # Display in Tkinter Label
        self.display_image_tk(tk_image, self.anomaly_map_label)

    def display_image(self, image, label, max_size=(300, 300)):
        # Resize image to fit within max_size while maintaining aspect ratio
        image.thumbnail(max_size, Image.ANTIALIAS)
        image_tk = ImageTk.PhotoImage(image)
        label.config(image=image_tk)
        label.image = image_tk  # Keep a reference

    def display_image_tk(self, tk_image, label):
        # Display Tkinter compatible image in the label
        label.config(image=tk_image)
        label.image = tk_image  # Keep a reference

if __name__ == "__main__":
    root = tk.Tk()
    root.geometry("600x730")  # Set the window size to 600x400 pixels
    app = AnomalyDetectionApp(root)
    root.mainloop()