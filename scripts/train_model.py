import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import json

# 1. Generación de Datos Sintéticos Mejorados (2000 muestras)
def generate_robust_data(n=2000):
    skills_list = ['flutter', 'dart', 'firebase', 'python', 'java', 'react', 'node', 'sql', 'javascript', 'aws']
    levels = ['junior', 'mid', 'senior', 'lead']
    
    data = []
    for _ in range(n):
        u_skill = np.random.choice(skills_list)
        u_level = np.random.choice(levels)
        j_skill = np.random.choice(skills_list)
        j_level = np.random.choice(levels)
        
        # Lógica de score más realista
        score = 0.0
        
        # Skills Match (Pesado: 0.7)
        if u_skill == j_skill:
            score += 0.7
        elif u_skill in ['flutter', 'dart'] and j_skill in ['flutter', 'dart']: # Relacionados
            score += 0.4
            
        # Experience Match (Pesado: 0.3)
        level_map = {'junior': 0, 'mid': 1, 'senior': 2, 'lead': 3}
        u_idx = level_map[u_level]
        j_idx = level_map[j_level]
        
        if u_idx == j_idx:
            score += 0.3
        elif u_idx > j_idx: # Sobrecalificado
            score += 0.2
        elif u_idx < j_idx: # Subcalificado
            score += 0.1
        
        data.append([u_skill, u_level, j_skill, j_level, min(score, 1.0)])
        
    return pd.DataFrame(data, columns=['u_skill', 'u_level', 'j_skill', 'j_level', 'label'])

print("Generando datos...")
df = generate_robust_data()

# 2. Encoding Consistente
le_skills = LabelEncoder()
le_levels = LabelEncoder()

# Asegurar cobertura total de categorías
le_skills.fit(['flutter', 'dart', 'firebase', 'python', 'java', 'react', 'node', 'sql', 'javascript', 'aws', 'other'])
le_levels.fit(['junior', 'mid', 'senior', 'lead'])

df['u_skill_enc'] = le_skills.transform(df['u_skill'])
df['j_skill_enc'] = le_skills.transform(df['j_skill'])
df['u_level_enc'] = le_levels.transform(df['u_level'])
df['j_level_enc'] = le_levels.transform(df['j_level'])

X = df[['u_skill_enc', 'u_level_enc', 'j_skill_enc', 'j_level_enc']].values
y = df['label'].values.astype(np.float32)

# 3. Modelo Perceptrón Multicapa (MLP)
model = tf.keras.Sequential([
    tf.keras.layers.Dense(32, activation='relu', input_shape=(4,)),
    tf.keras.layers.Dropout(0.2),
    tf.keras.layers.Dense(16, activation='relu'),
    tf.keras.layers.Dense(1, activation='sigmoid')
])

model.compile(optimizer='adam', loss='mse', metrics=['mae'])
print("Entrenando modelo...")
model.fit(X, y, epochs=100, batch_size=32, verbose=0)

# 4. Exportación a TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

with open('modelo_recomendacion.tflite', 'wb') as f:
    f.write(tflite_model)

encoders = {
    'skills': list(le_skills.classes_),
    'levels': list(le_levels.classes_)
}

with open('encoders.json', 'w') as f:
    json.dump(encoders, f)

print("¡IA Optimizada! Modelo y Encoders actualizados correctamente.")
