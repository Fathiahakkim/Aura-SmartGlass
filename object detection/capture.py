import cv2
import torch
import requests
import numpy as np
import firebase_admin
from firebase_admin import credentials, db
import face_recognition
import os

# ESP32-CAM URL (Update this with your IP)
ESP32_URL = "http://192.168.77.63/capture"

# Load YOLOv5 model
model = torch.hub.load('ultralytics/yolov5', 'yolov5s')

# Initialize Firebase
cred = credentials.Certificate("serviceAccountKey.json")  # Replace with your Firebase key
firebase_admin.initialize_app(cred, {
    "databaseURL": "https://glass-f7e3b-default-rtdb.firebaseio.com/"  # Replace with your Firebase DB URL
})
ref = db.reference("smart_glasses")

# Path to the folder containing known faces
KNOWN_FACES_DIR = "known_face"

# Lists to store encodings and names
known_encodings = []
known_names = []

# Load known faces
for filename in os.listdir(KNOWN_FACES_DIR):
    if filename.endswith(".jpg") or filename.endswith(".png"):
        image_path = os.path.join(KNOWN_FACES_DIR, filename)
        image = face_recognition.load_image_file(image_path)
        encoding = face_recognition.face_encodings(image)
        
        if encoding:
            known_encodings.append(encoding[0])
            known_names.append(os.path.splitext(filename)[0])  # Use filename as name

def get_frame():
    """Fetch an image from ESP32-CAM."""
    try:
        response = requests.get(ESP32_URL, timeout=5)
        if response.status_code == 200:
            img_arr = np.array(bytearray(response.content), dtype=np.uint8)
            frame = cv2.imdecode(img_arr, -1)
            return frame
    except requests.exceptions.RequestException as e:
        print("Connection error:", e)
        return None

while True:
    frame = get_frame()
    if frame is None:
        continue
    
    # Convert BGR (OpenCV) to RGB (for face recognition)
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    
    # Perform object detection
    results = model(frame)
    detected_objects = [obj['name'] for obj in results.pandas().xyxy[0].to_dict(orient="records")]
    
    # Detect faces
    face_locations = face_recognition.face_locations(rgb_frame)
    face_encodings = face_recognition.face_encodings(rgb_frame, face_locations)
    recognized_faces = []
    
    for (top, right, bottom, left), face_encoding in zip(face_locations, face_encodings):
        matches = face_recognition.compare_faces(known_encodings, face_encoding)
        name = "Unknown"
        
        # Find best match
        face_distances = face_recognition.face_distance(known_encodings, face_encoding)
        best_match_index = np.argmin(face_distances) if matches else None
        
        if best_match_index is not None and matches[best_match_index]:
            name = known_names[best_match_index]
        
        recognized_faces.append(name)
        
        # Draw face rectangle and name
        cv2.rectangle(frame, (left, top), (right, bottom), (0, 255, 0), 2)
        cv2.putText(frame, name, (left, top - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
    
    # Store results in Firebase
    ref.child("detected_objects").set(detected_objects)
    ref.child("recognized_faces").set(recognized_faces)
    
    # Show results
    cv2.imshow("ESP32-CAM Face & Object Detection", np.squeeze(results.render()))
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cv2.destroyAllWindows()
