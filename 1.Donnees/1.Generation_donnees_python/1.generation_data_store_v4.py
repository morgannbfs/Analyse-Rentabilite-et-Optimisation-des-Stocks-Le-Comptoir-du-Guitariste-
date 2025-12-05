import pandas as pd
from faker import Faker
import numpy as np
import datetime
from datetime import timedelta
import random
import os
import unicodedata

# =================================================================
# 0. CONFIGURATION GLOBALE
# =================================================================
CHEMIN_BASE = r"C:\Users\Morga\Desktop\projet_1_music_store\1.Donnees"
os.makedirs(CHEMIN_BASE, exist_ok=True)

NOMBRE_CLIENTS_UNIQUES = 50000
TRANSACTIONS_TOTALES = 109600 # Cible de transactions (non de lignes de faits)
DUREE_ANALYSE_JOURS = 1096
START_DATE = datetime.date(2022, 1, 1)
END_DATE = datetime.date(2024, 12, 31)

BASE_DAILY_TRANSACTIONS = 30
fake = Faker('fr_FR')

# Utilisation des seeds pour la reproductibilité des tirages aléatoires
random.seed(42)
np.random.seed(42)

# =================================================================
# UTILITAIRES
# =================================================================
def remove_accents(input_str):
    if isinstance(input_str, str):
        nfkd_form = unicodedata.normalize('NFD', input_str)
        cleaned_str = u"".join([c for c in nfkd_form if not unicodedata.combining(c)])
        return cleaned_str.replace("'", "").replace('oe', 'o').replace('Oe', 'O')
    return input_str

def assigner_poids_categorie(categorie):
    if 'Cordes' in categorie or categorie in ['Mediator', 'Sangle']:
        return 10.0
    elif categorie in ['Ampli']:
        return 3.0
    elif 'Guitare' in categorie:
        return 1.0
    return 1.0 

def assigner_poids_prix(prix):
    if prix < 20: return 3.0
    if prix < 300: return 2.0
    if prix < 800: return 1.0
    return 0.5

def assigner_poids_geographique(dept):
    DEPARTEMENTS_HIGH_WEIGHT = ['75', '92', '69', '59']
    DEPARTEMENTS_MEDIUM_WEIGHT = ['31', '44', '13']
    if dept in DEPARTEMENTS_HIGH_WEIGHT:
        return 2.5
    elif dept in DEPARTEMENTS_MEDIUM_WEIGHT:
        return 1.5
    else:
        return 0.8
        
def generer_client(client_id, adresse_aleatoire):
    """Génère un client en utilisant une ligne d'adresse fournie."""
    return {
        'client_id': f'CUST{client_id:05}',
        'nom_client': remove_accents(fake.last_name()),
        'prenom_client': remove_accents(fake.first_name()),
        'adresse_rue': remove_accents(fake.street_address()),
        'ville_client': adresse_aleatoire['Commune'],
        'code_postal': adresse_aleatoire['Code_postal'],
        'departement_client': adresse_aleatoire['departement_client'],
        'date_inscription': fake.date_between(start_date='-5y', end_date='today')
    }

# =================================================================
# SAISONNALITÉ
# =================================================================
SAISONNALITE = {
    'A1': [100, 85, 95, 96, 95, 105, 97, 85, 120, 110, 150, 230],
    'A2': [106, 90, 101, 102, 101, 111, 103, 90, 127, 117, 159, 244],
    'A3': [113, 96, 107, 108, 107, 119, 110, 96, 135, 124, 169, 260]
}

# =================================================================
# 1. GÉNÉRATION de dim_produits
# =================================================================
data_produits_list = [
    # --- Guitare Electrique (Marge ~40%) ---
    {'produit_id': 'GUE01', 'categorie': 'Guitare Electrique', 'reference_produit': 'Fender Strat Std', 'prix_vente': 580.00},
    {'produit_id': 'GUE02', 'categorie': 'Guitare Electrique', 'reference_produit': 'Epiphone Les Paul Std', 'prix_vente': 550.00},
    {'produit_id': 'GUE03', 'categorie': 'Guitare Electrique', 'reference_produit': 'Ibanez RG421', 'prix_vente': 410.00},
    {'produit_id': 'GUE04', 'categorie': 'Guitare Electrique', 'reference_produit': 'Squier Affinity Strat', 'prix_vente': 280.00},
    {'produit_id': 'GUE05', 'categorie': 'Guitare Electrique', 'reference_produit': 'Gibson Les Paul Std', 'prix_vente': 1390.00},
    {'produit_id': 'GUE06', 'categorie': 'Guitare Electrique', 'reference_produit': 'PRS SE Custom 24', 'prix_vente': 850.00},
    {'produit_id': 'GUE07', 'categorie': 'Guitare Electrique', 'reference_produit': 'Yamaha Pacifica 112', 'prix_vente': 250.00},
    {'produit_id': 'GUE08', 'categorie': 'Guitare Electrique', 'reference_produit': 'Gretsch Streamliner', 'prix_vente': 650.00},
    {'produit_id': 'GUE09', 'categorie': 'Guitare Electrique', 'reference_produit': 'Duesenberg Starplayer TV', 'prix_vente': 2599.00},
    {'produit_id': 'GUE10', 'categorie': 'Guitare Electrique', 'reference_produit': 'Jackson JS22 DKA', 'prix_vente': 230.00},
    
    # --- Guitare Folk (Marge ~40%) ---
    {'produit_id': 'GUF01', 'categorie': 'Guitare Folk', 'reference_produit': 'Martin D-18', 'prix_vente': 3199.00},
    {'produit_id': 'GUF02', 'categorie': 'Guitare Folk', 'reference_produit': 'Taylor GS Mini', 'prix_vente': 780.00},
    {'produit_id': 'GUF03', 'categorie': 'Guitare Folk', 'reference_produit': 'Yamaha FG800M', 'prix_vente': 279.00},
    {'produit_id': 'GUF04', 'categorie': 'Guitare Folk', 'reference_produit': 'Takamine GD20', 'prix_vente': 410.00},
    {'produit_id': 'GUF05', 'categorie': 'Guitare Folk', 'reference_produit': 'Fender CD-60', 'prix_vente': 200.00},
    {'produit_id': 'GUF06', 'categorie': 'Guitare Folk', 'reference_produit': 'Ibanez PF15', 'prix_vente': 270.00},
    {'produit_id': 'GUF07', 'categorie': 'Guitare Folk', 'reference_produit': 'Seagull S6 Original', 'prix_vente': 689.00},
    {'produit_id': 'GUF08', 'categorie': 'Guitare Folk', 'reference_produit': 'Guild D-120', 'prix_vente': 550.00},
    {'produit_id': 'GUF09', 'categorie': 'Guitare Folk', 'reference_produit': 'Epiphone Hummingbird', 'prix_vente': 750.00},
    {'produit_id': 'GUF10', 'categorie': 'Guitare Folk', 'reference_produit': 'Gibson L-00', 'prix_vente': 1750.00},
    
    # --- Sangle (Marge ~60%) ---
    {'produit_id': 'SNG01', 'categorie': 'Sangle', 'reference_produit': 'Sangle cuir Deluxe', 'prix_vente': 45.00},
    {'produit_id': 'SNG02', 'categorie': 'Sangle', 'reference_produit': 'Sangle Nylon Noir', 'prix_vente': 12.00},
    {'produit_id': 'SNG03', 'categorie': 'Sangle', 'reference_produit': 'Sangle Jacquard Vintage', 'prix_vente': 25.00},
    {'produit_id': 'SNG04', 'categorie': 'Sangle', 'reference_produit': 'Sangle en coton', 'prix_vente': 18.00},
    {'produit_id': 'SNG05', 'categorie': 'Sangle', 'reference_produit': 'Sangle Cuir Suede', 'prix_vente': 35.00},
    {'produit_id': 'SNG06', 'categorie': 'Sangle', 'reference_produit': 'Sangle Dunlop', 'prix_vente': 15.00},
    {'produit_id': 'SNG07', 'categorie': 'Sangle', 'reference_produit': 'Sangle Ernie Ball', 'prix_vente': 14.00},
    {'produit_id': 'SNG08', 'categorie': 'Sangle', 'reference_produit': "Sangle Levy's Tissus", 'prix_vente': 22.00},
    {'produit_id': 'SNG09', 'categorie': 'Sangle', 'reference_produit': 'Sangle en chanvre', 'prix_vente': 28.00},
    {'produit_id': 'SNG10', 'categorie': 'Sangle', 'reference_produit': 'Sangle Planet Waves', 'prix_vente': 16.00},

    # --- Mediator (Marge ~60%) ---
    {'produit_id': 'MED01', 'categorie': 'Mediator', 'reference_produit': 'Dunlop Primetone Standard Grip 0,73', 'prix_vente': 12.50},
    {'produit_id': 'MED02', 'categorie': 'Mediator', 'reference_produit': 'Dunlop Electric Pick Variety Pack', 'prix_vente': 7.50},
    {'produit_id': 'MED03', 'categorie': 'Mediator', 'reference_produit': 'Dunlop Tortex Standard 0,88', 'prix_vente': 6.90},
    {'produit_id': 'MED04', 'categorie': 'Mediator', 'reference_produit': 'Dunlop Nylon Max Grip 0.73 Player Pk', 'prix_vente': 6.90},
    {'produit_id': 'MED05', 'categorie': 'Mediator', 'reference_produit': 'Fender Ocean Turq Pick Extra Heavy', 'prix_vente': 5.50},
    {'produit_id': 'MED06', 'categorie': 'Mediator', 'reference_produit': 'Fender Triangle Picks Shell Set Med', 'prix_vente': 7.50},
    {'produit_id': 'MED07', 'categorie': 'Mediator', 'reference_produit': 'Ibanez PPA16HSG-RD Pick Set', 'prix_vente': 7.90},
    {'produit_id': 'MED08', 'categorie': 'Mediator', 'reference_produit': 'Gibson Perloid Picks Medium 12pc', 'prix_vente': 4.90},
    {'produit_id': 'MED09', 'categorie': 'Mediator', 'reference_produit': 'Gibson Picks Wedge Style Heavy Set', 'prix_vente': 19.90},
    {'produit_id': 'MED10', 'categorie': 'Mediator', 'reference_produit': 'Taylor Celluloid Pick Tin Set', 'prix_vente': 16.90},

    # --- Cordes Folk (Marge ~60%) ---
    {'produit_id': 'CDF01', 'categorie': 'Cordes Folk', 'reference_produit': 'Elixir Nanoweb Light Phosphor Bronze', 'prix_vente': 16.90},
    {'produit_id': 'CDF02', 'categorie': 'Cordes Folk', 'reference_produit': 'D\'Addario EJ16 Light', 'prix_vente': 8.70},
    {'produit_id': 'CDF03', 'categorie': 'Cordes Folk', 'reference_produit': 'Adamas 1717NU', 'prix_vente': 15.70},
    {'produit_id': 'CDF04', 'categorie': 'Cordes Folk', 'reference_produit': 'Ernie Ball 2003 Earthwood Bronze', 'prix_vente': 5.80},
    {'produit_id': 'CDF05', 'categorie': 'Cordes Folk', 'reference_produit': 'GHS Bright Bronze BB60X 009-042', 'prix_vente': 13.40},
    {'produit_id': 'CDF06', 'categorie': 'Cordes Folk', 'reference_produit': 'Ernie Ball Paradigm Phosphor B. EL 10-50', 'prix_vente': 16.60},
    {'produit_id': 'CDF07', 'categorie': 'Cordes Folk', 'reference_produit': 'Thomastik SB110 Spectrum Bronze', 'prix_vente': 19.60},
    {'produit_id': 'CDF08', 'categorie': 'Cordes Folk', 'reference_produit': 'Savarez Argentine 1510', 'prix_vente': 9.70},
    {'produit_id': 'CDF09', 'categorie': 'Cordes Folk', 'reference_produit': 'Martin Guitar MA-170 Authentic Acoustic Set', 'prix_vente': 6.90},
    {'produit_id': 'CDF10', 'categorie': 'Cordes Folk', 'reference_produit': 'Daddario EJ16-3D', 'prix_vente': 24.90},

    # --- Ampli (Marge ~40%) ---
    {'produit_id': 'AMP01', 'categorie': 'Ampli', 'reference_produit': 'Fender Blues Junior', 'prix_vente': 769.00},
    {'produit_id': 'AMP02', 'categorie': 'Ampli', 'reference_produit': 'Boss Katana 50 (Gen 3)', 'prix_vente': 285.00},
    {'produit_id': 'AMP03', 'categorie': 'Ampli', 'reference_produit': 'Marshall MG30GFX', 'prix_vente': 179.00},
    {'produit_id': 'AMP04', 'categorie': 'Ampli', 'reference_produit': 'Blackstar FLY3 Mini', 'prix_vente': 70.00},
    {'produit_id': 'AMP05', 'categorie': 'Ampli', 'reference_produit': 'Vox AC30', 'prix_vente': 1200.00},
    {'produit_id': 'AMP06', 'categorie': 'Ampli', 'reference_produit': 'Positive Grid Spark 40', 'prix_vente': 218.00},
    {'produit_id': 'AMP07', 'categorie': 'Ampli', 'reference_produit': 'Line 6 Catalyst 60', 'prix_vente': 269.00},
    {'produit_id': 'AMP08', 'categorie': 'Ampli', 'reference_produit': 'Orange Crush 20RT', 'prix_vente': 225.00},
    {'produit_id': 'AMP09', 'categorie': 'Ampli', 'reference_produit': 'Roland Cube 10GX', 'prix_vente': 179.00},
    {'produit_id': 'AMP10', 'categorie': 'Ampli', 'reference_produit': 'Peavey Vypyr X1', 'prix_vente': 229.00},
    
    # --- Cordes d'Electrique (Marge ~60%) ---
    {'produit_id': 'CDE01', 'categorie': 'Cordes Electrique', 'reference_produit': 'Ernie Ball 2221 Regular Slinky', 'prix_vente': 5.90},
    {'produit_id': 'CDE02', 'categorie': 'Cordes Electrique', 'reference_produit': 'D\'Addario EXL110 Regular Light', 'prix_vente': 6.90},
    {'produit_id': 'CDE03', 'categorie': 'Cordes Electrique', 'reference_produit': 'Elixir Nanoweb Light (Single)', 'prix_vente': 13.90},
    {'produit_id': 'CDE04', 'categorie': 'Cordes Electrique', 'reference_produit': 'Ernie Ball Super Slinky 2223', 'prix_vente': 5.70},
    {'produit_id': 'CDE05', 'categorie': 'Cordes Electrique', 'reference_produit': 'D\'Addario NYXL0946 Hybrid Light', 'prix_vente': 13.90},
    {'produit_id': 'CDE06', 'categorie': 'Cordes Electrique', 'reference_produit': 'Ernie Ball 3221 (3-Pack)', 'prix_vente': 16.90},
    {'produit_id': 'CDE07', 'categorie': 'Cordes Electrique', 'reference_produit': 'Fender 250L (3-Pack)', 'prix_vente': 13.90},
    {'produit_id': 'CDE08', 'categorie': 'Cordes Electrique', 'reference_produit': 'Ernie Ball Power Slinky 2220', 'prix_vente': 5.90},
    {'produit_id': 'CDE09', 'categorie': 'Cordes Electrique', 'reference_produit': 'Pyramid Pure Nickel (Jazz)', 'prix_vente': 6.40},
    {'produit_id': 'CDE10', 'categorie': 'Cordes Electrique', 'reference_produit': 'D\'Addario EXL125 Super Light', 'prix_vente': 7.90},
]

for item in data_produits_list:
    item['categorie'] = remove_accents(item['categorie'])
    item['reference_produit'] = remove_accents(item['reference_produit'])

df_produits = pd.DataFrame(data_produits_list)

# FIX: Vectorisation complète du calcul Marge/Coût
df_produits['marge_pct'] = df_produits['categorie'].apply(
    lambda c: 0.60 if c in ['Sangle', 'Mediator', 'Cordes Folk', 'Cordes Electrique'] else 0.40
)
df_produits['cout'] = round(df_produits['prix_vente'] * (1 - df_produits['marge_pct']), 2)
df_produits['marge_unitaire'] = round(df_produits['prix_vente'] - df_produits['cout'], 2)
df_produits.drop(columns=['marge_pct'], inplace=True)


# --- Calcul des Poids de Sélection Produits ---
df_produits['poids_categorie'] = df_produits['categorie'].apply(assigner_poids_categorie)
df_produits['poids_prix'] = df_produits['prix_vente'].apply(assigner_poids_prix)
df_produits['poids_produit_final'] = df_produits['poids_categorie'] * df_produits['poids_prix']

df_produits.to_csv(os.path.join(CHEMIN_BASE, 'dim_produits.csv'), index=False, encoding='utf-8')
print(f"✅ dim_produits.csv créé ({len(df_produits)} lignes) avec pondération produit.")

# Pré-calculs utiles pour mapping rapide (pour fact_ventes)
produit_map = df_produits.set_index('produit_id').to_dict('index')
all_produit_ids = df_produits['produit_id'].tolist()
weights_produit_selection = df_produits['poids_produit_final'].astype(float).values
weights_produit_norm = weights_produit_selection / weights_produit_selection.sum()

# Indique si le produit est "gros" (quantité=1) ou consommable
is_single_qty = {pid: ( (pid.startswith('GUE') or pid.startswith('GUF') or pid.startswith('AMP')) ) for pid in all_produit_ids}
prix_map = {pid: produit_map[pid]['prix_vente'] for pid in all_produit_ids}
marge_map = {pid: produit_map[pid]['marge_unitaire'] for pid in all_produit_ids}

# =================================================================
# 2. GÉNÉRATION de dim_clients (FIXED: Pondération en cascade et garantie de densité)
# =================================================================
Communes_data = pd.DataFrame()
try:
    # --- CHARGEMENT ET PRÉPARATION DES DONNÉES DE COMMUNES ---
    Communes_data = pd.read_csv(os.path.join(CHEMIN_BASE, "1.Communes.csv"), sep=';', encoding='utf-8')
    Communes_data = Communes_data.dropna(subset=['Code_postal', 'Commune']).copy()
    Communes_data['Code_postal'] = Communes_data['Code_postal'].astype(str).str.zfill(5)
    Communes_data['Commune'] = Communes_data['Commune'].apply(remove_accents)
    Communes_data['departement_client'] = Communes_data['Code_postal'].str[:2]
    print(f"✅ Fichier 1.Communes.csv chargé ({len(Communes_data)} lignes).")
except Exception as e:
    print(f"⚠️ 1.Communes.csv absent ou erreur ({e}) — fallback Faker utilisé.")
    Communes_data = pd.DataFrame({
        'Commune': [remove_accents(fake.city()) for _ in range(500)],
        'Code_postal': [fake.postcode()[:5] for _ in range(500)]
    })
    Communes_data['departement_client'] = Communes_data['Code_postal'].str[:2]


# --------------------------------------------------------------------------------------
# --- NOUVELLE LOGIQUE DE GÉNÉRATION DES CLIENTS (Garantie de Densité) ---
# --------------------------------------------------------------------------------------

DEPARTEMENTS_CIBLES = ['75', '92', '69', '59', '31', '44', '13']
NOMBRE_CLIENTS_GARANTIS_PAR_DEPT_CIBLE = 800  # Minimum de 800 clients pour chacun des 7 départements cibles

# Filtrage des villes pour les départements cibles
communes_cibles = Communes_data[ 
    Communes_data['departement_client'].isin(DEPARTEMENTS_CIBLES)
].copy()

# Filtrage pour le reste des départements (le reste du pays)
# FIX: Utilise le tilde (~) pour sélectionner les départements NON CIBLES
communes_autres = Communes_data[
    ~Communes_data['departement_client'].isin(DEPARTEMENTS_CIBLES)
].copy()


liste_clients = []
client_id_counter = 1

# --- ÉTAPE 1: GARANTIE CLIENTS CIBLES ---
print(f"➡️ Garantie d'au moins {NOMBRE_CLIENTS_GARANTIS_PAR_DEPT_CIBLE} clients par département cible ({len(DEPARTEMENTS_CIBLES)} dpts)...")

for dept in DEPARTEMENTS_CIBLES:
    adresses_dept = communes_cibles[
        communes_cibles['departement_client'] == dept
    ]
    
    nb_a_tirer = min(NOMBRE_CLIENTS_GARANTIS_PAR_DEPT_CIBLE, len(adresses_dept))
    
    adresses_selectionnees = adresses_dept.sample(
        nb_a_tirer, 
        # Utilise replace=True uniquement si pas assez d'adresses uniques
        replace=(nb_a_tirer > len(adresses_dept)) 
    ).reset_index(drop=True)
    
    for i in range(nb_a_tirer):
        liste_clients.append(generer_client(client_id_counter, adresses_selectionnees.iloc[i]))
        client_id_counter += 1

# --- ÉTAPE 2: REMPLISSAGE ALÉATOIRE ---
clients_actuels = len(liste_clients)
nombre_clients_restants = NOMBRE_CLIENTS_UNIQUES - clients_actuels

print(f"➡️ Clients garantis créés: {clients_actuels}. Reste à générer: {nombre_clients_restants} clients.")

if nombre_clients_restants > 0:
    # Tire des adresses dans l'ensemble de Communes_data pour le reste des clients
    adresses_globales = Communes_data.sample(nombre_clients_restants, replace=True).reset_index(drop=True)
    
    for i in range(nombre_clients_restants):
        liste_clients.append(generer_client(client_id_counter, adresses_globales.iloc[i]))
        client_id_counter += 1

df_clients = pd.DataFrame(liste_clients)
# --------------------------------------------------------------------------------------


# Application des Poids (inchangée, mais maintenant sur une base de clients plus pertinente)
df_clients['poids_geographique'] = df_clients['departement_client'].apply(assigner_poids_geographique)

# Pondération de fidélité en cascade (TOP 500 VIP, 500-2000 Fidèles)
df_clients['poids_fidelite'] = 1.0
df_clients.loc[df_clients.index < 500, 'poids_fidelite'] = 3.0
df_clients.loc[(df_clients.index >= 500) & (df_clients.index < 2000), 'poids_fidelite'] = 1.8

# Calcul du poids final pour la sélection pondérée
df_clients['poids_selection_final'] = df_clients['poids_geographique'] * df_clients['poids_fidelite']

df_clients.to_csv(os.path.join(CHEMIN_BASE, 'dim_clients.csv'), index=False, encoding='utf-8')
print(f"✅ dim_clients.csv créé ({len(df_clients)} lignes) avec nouvelle densité client.")

client_ids = df_clients['client_id'].tolist()
weights_client_selection = df_clients['poids_selection_final'].astype(float).values
weights_client_norm = weights_client_selection / weights_client_selection.sum()

# =================================================================
# 3. GÉNÉRATION de dim_dates
# =================================================================
date_list = []
current_date = START_DATE
while current_date <= END_DATE:
    is_weekend = current_date.weekday() >= 5
    date_list.append({
        'date_clef': current_date,
        'annee': current_date.year,
        'mois': current_date.month,
        'jour_semaine': current_date.strftime('%A'),
        'est_weekend': is_weekend
    })
    current_date += timedelta(days=1)

df_dates = pd.DataFrame(date_list)
df_dates.to_csv(os.path.join(CHEMIN_BASE, 'dim_dates.csv'), index=False, encoding='utf-8')
print(f"✅ dim_dates.csv créé ({len(df_dates)} lignes).")

# =================================================================
# 4. GÉNÉRATION VECTORISÉE de fact_ventes
# =================================================================
print("\n🔄 Démarrage génération vectorisée de fact_ventes...")

# 1) Calcul du nombre de transactions par jour (vectorisé)
df_dates['annee_index'] = df_dates['annee'] - START_DATE.year + 1
def get_indice(row):
    year_str = f"A{int(row['annee_index'])}"
    month_index = int(row['mois']) - 1
    try:
        return SAISONNALITE[year_str][month_index]
    except Exception:
        return 100

df_dates['indice_saison'] = df_dates.apply(get_indice, axis=1)
df_dates['weekend_factor'] = df_dates['est_weekend'].apply(lambda x: 1.5 if x else 1.0)
df_dates['target_transactions'] = (BASE_DAILY_TRANSACTIONS * (df_dates['indice_saison'] / 100.0) * df_dates['weekend_factor']).round().astype(int)
df_dates.loc[df_dates['target_transactions'] < 1, 'target_transactions'] = 1

transactions_per_day = df_dates['target_transactions'].values
dates_array = np.array(df_dates['date_clef'].tolist())
total_transactions = int(transactions_per_day.sum())
print(f"➡️ Total transactions planifiées (estimé) : {total_transactions:,}")

# 2) Tirage massif des clients — un client par transaction
chosen_clients_per_transaction = np.random.choice(client_ids, size=total_transactions, p=weights_client_norm)

# 3) Transaction -> date mapping (répéter chaque date selon le nb de transactions)
date_repeats = np.repeat(dates_array, transactions_per_day)

# 4) Order IDs
order_ids = np.arange(1, total_transactions + 1)

# 5) Heures : Tirage massif d'heures pondérées
heures_weekend = np.array(list(range(10, 23)))
poids_weekend = np.array(([0.05] * 4) + ([0.10] * 5) + ([0.15] * 4))
poids_weekend = poids_weekend / poids_weekend.sum()

heures_weekday = np.array(list(range(9, 23)))
poids_weekday = np.array(([0.03] * 9) + ([0.15] * 5))
poids_weekday = poids_weekday / poids_weekday.sum()

# Identification des indices weekend/weekday
idx_weekend = np.where(np.isin(
    date_repeats.astype(object), # FIX: S'assurer que le type est object pour la comparaison
    df_dates[df_dates['est_weekend']]['date_clef'].values.astype(object)
))[0]
idx_weekday = np.setdiff1d(np.arange(total_transactions), idx_weekend)

hours_array = np.empty(total_transactions, dtype=int)
if len(idx_weekend) > 0:
    hours_array[idx_weekend] = np.random.choice(heures_weekend, size=len(idx_weekend), p=poids_weekend)
if len(idx_weekday) > 0:
    hours_array[idx_weekday] = np.random.choice(heures_weekday, size=len(idx_weekday), p=poids_weekday)

minutes_array = np.random.randint(0, 60, size=total_transactions)
seconds_array = np.random.randint(0, 60, size=total_transactions)
# FIX: Assure le format 24h
heure_strings = [f"{h:02d}:{m:02d}:{s:02d}" for h, m, s in zip(hours_array, minutes_array, seconds_array)]

# 6) Nombre de lignes par transaction (1 à 5)
num_line_items_per_tx = np.random.randint(1, 6, size=total_transactions)
total_line_items = int(num_line_items_per_tx.sum())
print(f"➡️ Total lignes de facturation (lignes produit) : {total_line_items:,}")

# 7) Expand transaction-level arrays to line-item level
order_id_lines = np.repeat(order_ids, num_line_items_per_tx)
client_id_lines = np.repeat(chosen_clients_per_transaction, num_line_items_per_tx)
date_lines = np.repeat(date_repeats, num_line_items_per_tx)
heure_lines = np.repeat(heure_strings, num_line_items_per_tx)

# 8) Tirage massif des produits pour chaque ligne (avec pondération)
chosen_produits_lines = np.random.choice(all_produit_ids, size=total_line_items, p=weights_produit_norm)

# 9) Quantités : si produit "gros" => 1, sinon 1..4
is_single = np.array([1 if is_single_qty[pid] else 0 for pid in chosen_produits_lines], dtype=int)
# FIX: Limite à 4 pour les accessoires
quantities = np.where(is_single == 1, 1, np.random.randint(1, 5, size=total_line_items))

# 10) Prix unitaire et marge mapping (vectorisé)
prix_unitaire_lines = np.array([prix_map[pid] for pid in chosen_produits_lines], dtype=float)
marge_unitaire_lines = np.array([marge_map[pid] for pid in chosen_produits_lines], dtype=float)

ca_lines = np.round(prix_unitaire_lines * quantities, 2)
marge_lines = np.round(marge_unitaire_lines * quantities, 2)

# 11) Assembler DataFrame fact_ventes
df_ventes = pd.DataFrame({
    'order_id': order_id_lines,
    'client_id': client_id_lines,
    'produit_id': chosen_produits_lines,
    'date_transaction': date_lines,
    'heure_transaction': heure_lines,
    'quantite_vendue': quantities,
    'prix_vente_unitaire_enregistre': prix_unitaire_lines,
    'chiffre_affaire_transaction': ca_lines,
    'marge_transaction': marge_lines
})

# 12) Exporter
csv_path = os.path.join(CHEMIN_BASE, 'fact_ventes.csv')
parquet_path = os.path.join(CHEMIN_BASE, 'fact_ventes.parquet')
df_ventes.to_csv(csv_path, index=False, encoding='utf-8')
df_ventes.to_parquet(parquet_path, index=False)
print(f"✅ fact_ventes.csv ({len(df_ventes):,} lignes) et fact_ventes.parquet créés.")

# 13) Validation (comptage mois/année)
df_ventes['mois'] = pd.to_datetime(df_ventes['date_transaction']).dt.month
df_ventes['annee'] = pd.to_datetime(df_ventes['date_transaction']).dt.year
print("\n📊 Validation Saisonnalité (extrait):")
for year in [2022, 2023, 2024]:
    for month in range(1, 13):
        count = len(df_ventes[(df_ventes['annee'] == year) & (df_ventes['mois'] == month)])
        print(f"{year}-{month:02d}: {count:6d} lignes")

print("\n🔥 Génération terminée. Vous pouvez passer à l'analyse SQL.")