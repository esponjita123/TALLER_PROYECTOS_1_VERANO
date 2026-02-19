"""
Wanka Trabajo - Script de Entrenamiento del Modelo de Recomendación
Genera modelo_recomendacion.tflite y encoders.json para matching de oficios/empleos.

Uso: python scripts/train_model.py
Salida: assets/ml/modelo_recomendacion.tflite + assets/ml/encoders.json
"""
import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.preprocessing import LabelEncoder
import json
import os

# ═══════════════════════════════════════════════════════
# 1. DEFINICIÓN DE OFICIOS, NIVELES Y TIPOS
# ═══════════════════════════════════════════════════════

SKILLS = [
    # Construcción y mantenimiento
    'albañilería', 'carpintería', 'ebanistería', 'pintura', 'electricidad',
    'plomería', 'soldadura', 'metalurgia', 'vidriería',
    # Textil y confección
    'costura', 'sastrería', 'bordado', 'tejido',
    # Alimentos
    'cocina', 'panadería', 'pastelería', 'bartender',
    # Servicios
    'limpieza', 'jardinería', 'peluquería', 'barbería',
    'conducción', 'mecánica', 'cuidado_personas',
    # Profesional / tech
    'contabilidad', 'ventas', 'administración', 'diseño',
    'programación', 'marketing',
    # Fallback
    'general',
]

# Relaciones entre oficios (skills relacionados reciben score parcial)
SKILL_GROUPS = {
    'construcción': ['albañilería', 'carpintería', 'ebanistería', 'pintura',
                     'electricidad', 'plomería', 'soldadura', 'metalurgia', 'vidriería'],
    'textil': ['costura', 'sastrería', 'bordado', 'tejido'],
    'alimentos': ['cocina', 'panadería', 'pastelería', 'bartender'],
    'belleza': ['peluquería', 'barbería'],
    'profesional': ['contabilidad', 'ventas', 'administración', 'diseño',
                    'programación', 'marketing'],
    'servicios': ['limpieza', 'jardinería', 'conducción', 'mecánica', 'cuidado_personas'],
}

# Pares de oficios muy cercanos (score extra alto)
CLOSE_PAIRS = [
    ('carpintería', 'ebanistería'),
    ('costura', 'sastrería'),
    ('cocina', 'panadería'),
    ('cocina', 'pastelería'),
    ('panadería', 'pastelería'),
    ('peluquería', 'barbería'),
    ('soldadura', 'metalurgia'),
    ('electricidad', 'plomería'),
    ('albañilería', 'pintura'),
    ('ventas', 'marketing'),
    ('contabilidad', 'administración'),
    ('bordado', 'tejido'),
]

LEVELS = ['básico', 'intermedio', 'avanzado', 'experto']
JOB_TYPES = ['profesional', 'temporal', 'medio-tiempo', 'por-obra', 'remoto']


def are_in_same_group(s1, s2):
    """Retorna True si dos skills están en el mismo grupo."""
    for group in SKILL_GROUPS.values():
        if s1 in group and s2 in group:
            return True
    return False


def are_close_pair(s1, s2):
    """Retorna True si dos skills son un par cercanamente relacionado."""
    return (s1, s2) in CLOSE_PAIRS or (s2, s1) in CLOSE_PAIRS


# ═══════════════════════════════════════════════════════
# 2. GENERACIÓN DE DATOS DE ENTRENAMIENTO
# ═══════════════════════════════════════════════════════

def generate_training_data(n=3000):
    """Genera datos sintéticos con lógica de scoring realista."""
    level_map = {'básico': 0, 'intermedio': 1, 'avanzado': 2, 'experto': 3}
    data = []

    for _ in range(n):
        u_skill = np.random.choice(SKILLS[:-1])  # Excluir 'general'
        u_level = np.random.choice(LEVELS)
        j_skill = np.random.choice(SKILLS[:-1])
        j_level = np.random.choice(LEVELS)
        j_type = np.random.choice(JOB_TYPES)
        loc_match = np.random.choice([0.0, 0.5, 1.0], p=[0.3, 0.3, 0.4])

        score = 0.0

        # ── Skill Match (peso: 0.50) ──
        if u_skill == j_skill:
            score += 0.50
        elif are_close_pair(u_skill, j_skill):
            score += 0.35
        elif are_in_same_group(u_skill, j_skill):
            score += 0.20
        else:
            score += 0.0

        # ── Level Match (peso: 0.20) ──
        u_idx = level_map[u_level]
        j_idx = level_map[j_level]
        diff = abs(u_idx - j_idx)

        if diff == 0:
            score += 0.20
        elif diff == 1:
            score += 0.14
            if u_idx > j_idx:  # Sobrecalificado
                score += 0.03
        elif diff == 2:
            score += 0.06
        else:
            score += 0.02

        # ── Job Type Affinity (peso: 0.10) ──
        type_affinity = {
            'profesional': {'experto': 0.10, 'avanzado': 0.08, 'intermedio': 0.05, 'básico': 0.03},
            'temporal':    {'experto': 0.04, 'avanzado': 0.06, 'intermedio': 0.08, 'básico': 0.10},
            'medio-tiempo':{'experto': 0.05, 'avanzado': 0.06, 'intermedio': 0.08, 'básico': 0.08},
            'por-obra':    {'experto': 0.06, 'avanzado': 0.08, 'intermedio': 0.08, 'básico': 0.10},
            'remoto':      {'experto': 0.08, 'avanzado': 0.07, 'intermedio': 0.06, 'básico': 0.05},
        }
        score += type_affinity.get(j_type, {}).get(u_level, 0.05)

        # ── Location Match (peso: 0.15) ──
        score += loc_match * 0.15

        # ── Ruido para diversidad ──
        noise = np.random.normal(0, 0.03)
        score = np.clip(score + noise, 0.0, 1.0)

        # ── Bonus para empleo remoto si skill es profesional/tech ──
        if j_type == 'remoto' and j_skill in ['programación', 'diseño', 'marketing',
                                                 'contabilidad', 'administración']:
            score = min(score + 0.05, 1.0)

        data.append([u_skill, u_level, j_skill, j_level, j_type, loc_match, float(score)])

    return pd.DataFrame(data, columns=[
        'u_skill', 'u_level', 'j_skill', 'j_level', 'j_type', 'loc_match', 'label'
    ])


# ═══════════════════════════════════════════════════════
# 3. ENTRENAMIENTO
# ═══════════════════════════════════════════════════════

def train():
    print("🔧 Generando datos de entrenamiento (3000 muestras)...")
    df = generate_training_data(3000)

    # Encoders
    le_skills = LabelEncoder()
    le_levels = LabelEncoder()
    le_types = LabelEncoder()

    le_skills.fit(SKILLS)
    le_levels.fit(LEVELS)
    le_types.fit(JOB_TYPES)

    df['u_skill_enc'] = le_skills.transform(df['u_skill'])
    df['j_skill_enc'] = le_skills.transform(df['j_skill'])
    df['u_level_enc'] = le_levels.transform(df['u_level'])
    df['j_level_enc'] = le_levels.transform(df['j_level'])
    df['j_type_enc'] = le_types.transform(df['j_type'])

    X = df[['u_skill_enc', 'u_level_enc', 'j_skill_enc', 'j_level_enc',
            'j_type_enc', 'loc_match']].values.astype(np.float32)
    y = df['label'].values.astype(np.float32)

    print(f"📊 Features: {X.shape[1]} | Muestras: {X.shape[0]}")
    print(f"📈 Score promedio: {y.mean():.3f} | Min: {y.min():.3f} | Max: {y.max():.3f}")

    # Modelo MLP más profundo
    model = tf.keras.Sequential([
        tf.keras.layers.Dense(64, activation='relu', input_shape=(6,)),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(32, activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(16, activation='relu'),
        tf.keras.layers.Dense(1, activation='sigmoid')
    ])

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss='mse',
        metrics=['mae']
    )

    print("🧠 Entrenando modelo...")
    history = model.fit(
        X, y,
        epochs=150,
        batch_size=32,
        validation_split=0.2,
        verbose=0
    )

    val_mae = history.history['val_mae'][-1]
    print(f"✅ Entrenamiento completado | Val MAE: {val_mae:.4f}")

    # ═══════════════════════════════════════════════════════
    # 4. EXPORTACIÓN
    # ═══════════════════════════════════════════════════════

    # Detectar directorio de salida (compatible con Colab y local)
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_dir = os.path.dirname(script_dir)
        ml_dir = os.path.join(project_dir, 'assets', 'ml')
    except NameError:
        # En Google Colab / notebooks, __file__ no existe
        ml_dir = os.path.join(os.getcwd(), 'assets_ml')
        print(f"⚠️  Ejecutando en notebook. Archivos se guardan en: {ml_dir}")
    os.makedirs(ml_dir, exist_ok=True)

    # TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()

    tflite_path = os.path.join(ml_dir, 'modelo_recomendacion.tflite')
    with open(tflite_path, 'wb') as f:
        f.write(tflite_model)
    print(f"📦 Modelo guardado: {tflite_path}")

    # Encoders JSON
    encoders = {
        'skills': list(le_skills.classes_),
        'levels': list(le_levels.classes_),
        'types': list(le_types.classes_),
    }

    encoders_path = os.path.join(ml_dir, 'encoders.json')
    with open(encoders_path, 'w', encoding='utf-8') as f:
        json.dump(encoders, f, ensure_ascii=False, indent=2)
    print(f"📋 Encoders guardados: {encoders_path}")

    # Skill groups para referencia
    groups_path = os.path.join(ml_dir, 'skill_groups.json')
    with open(groups_path, 'w', encoding='utf-8') as f:
        json.dump(SKILL_GROUPS, f, ensure_ascii=False, indent=2)
    print(f"📋 Skill groups guardados: {groups_path}")

    print("\n🎉 ¡IA actualizada exitosamente!")
    print(f"   Skills: {len(SKILLS)} oficios")
    print(f"   Levels: {LEVELS}")
    print(f"   Types: {JOB_TYPES}")
    print(f"   Features: 6 (skill_u, level_u, skill_j, level_j, type_j, loc_match)")


if __name__ == '__main__':
    train()
