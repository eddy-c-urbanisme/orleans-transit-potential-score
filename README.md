# Orléans Transit Potential Score (TPS)
**Modélisation spatiale et ingénierie des données pour l'aide à la décision : identifier les « zones blanches » du réseau TAO et justifier par la donnée le tracé d'une 3ème ligne structurante (Tramway / BHNS) sur Orléans Métropole.**

---

## 1. Contexte et Problématique
Le réseau de tramway d'Orléans Métropole (Lignes A et B) a été mis en service respectivement en 2000 et 2012. En 2026, face aux mutations démographiques, à l'étalement périurbain et à l'émergence de nouvelles polarités d'emploi et de services, **comment objectiver les carences de desserte des 22 communes de la métropole (117 IRIS) ?**

Ce projet développe un **Transit Potential Score (TPS)** croisant deux dimensions complémentaires à l'échelle infracommunale (IRIS) :
* **Le Potentiel Émetteur (Demande sociale) :** Volume démographique pondéré par la présence de publics captifs des transports collectifs (scolaires, étudiants, seniors, ouvriers en horaires décalés, personnes sans activité professionnelle).
* **Le Potentiel Récepteur (Attractivité urbaine) :** Hiérarchisation et pondération des équipements générateurs de flux (gares, pôles hospitaliers, enseignement supérieur et secondaire, commerces et services de proximité).

### Cadre théorique & Littérature scientifique
Ce modèle s'inspire directement des travaux américains sur le **Transit Score Index** développés par la *Delaware Valley Regional Planning Commission (DVRPC)* et *NJ TRANSIT*, tout en les adaptant aux bases de données infracommunales françaises (INSEE) :
* **Marchwinski, T. (2000).** *The 2020 Transit Score Report: Possibilities for the Future*, NJ TRANSIT Business Planning Department. *(Définition des seuils d'investissement entre bus local et transport en site propre, et rayons d'attractivité piétonne de 400m pour les bus et 800m pour les modes lourds)*.
* **Lutin, J. M., Krykewycz, G. R., Hacker, J. F., & Marchwinski, T. W. (2008).** *Transit Score: Screening Model for Evaluating Community Suitability for Transit Investments*, Transportation Research Record (TRR), No. 2063, pp. 115–124. *(Modélisation des origines par publics captifs : jeunes, seniors, ménages non motorisés).*
* **Apport méthodologique du présent projet :** Là où L'étude de Lutin et al. (2008, p. 122) souligne la nécessité d'étendre le volet « Récepteur » au-delà des seuls trajets domicile-travail (*journey-to-work*), notre modèle exploite la **Base Permanente des Équipements (BPE)** pour intégrer les générateurs de flux hors-travail (enseignement supérieur, pôles hospitaliers, commerces, loisirs).

---

## 2. Architecture du Pipeline (4 Phases)

* **Phase 1 — Ingénierie des données & Modélisation relationnelle (SQLite)** *(Terminée)*
  * Extraction et nettoyage des données brutes, profilage des métadonnées INSEE, création de l'algorithme des scores et agrégation par IRIS.
* **Phase 2 — Intelligence Spatiale & Aide à la décision (QGIS & Power BI)** *(En cours)*
  * Pondération surfacique (calcul de la **densité réelle des besoins au km²** via la géométrie des polygones `$area`), normalisation Min-Max `[0-100]`, croisement avec les données GTFS du réseau TAO (isochrones piétons de 800m) et création d'un tableau de bord interactif pour les élus.
* **Phase 3 — Industrialisation et Automatisation (Python)** *(À venir)*
  * Automatisation de la collecte (API INSEE) et de l'exécution des scripts SQLite.
* **Phase 4 — Conception multimodale & Insertion 3D (Blender / BlenderGIS)** *(À venir)*
  * Modélisation 3D d'une station ou d'une section de la potentielle future ligne.

---

## 3. Méthodologie de Scoring (Phase 1 — SQLite)

### A. Sources de données mobilisées (INSEE)
* **Démographie :** [Recensement de la population 2022 — Base infracommunale (IRIS)](https://www.insee.fr/fr/statistiques/8647014)
* **Équipements :** [Base Permanente des Équipements (BPE) 2025 géolocalisée](https://www.insee.fr/fr/statistiques/8217525)
* **Référentiel géographique :** [Table d'appartenance géographique des IRIS 2026](https://www.insee.fr/fr/information/7708995) *(Périmètre filtré : 22 communes / 117 IRIS d'Orléans Métropole)*.

### B. Modèle Émetteur (`score_pop`) : Pondération des publics captifs
La population totale (`P22_POP`) constitue le socle de référence (**1 point par résident**). Afin d'éviter l'écueil du secret statistique inhérent aux bases fiscales (Filosofi/CAF) sur les petites communes périurbaines, la vulnérabilité socio-économique est modélisée par des variables *proxys* issues du recensement :

| Variable INSEE | Public ciblé | Poids total | Formule SQL (Socle 1 + Bonus) | Justification mobilité |
| :--- | :--- | :---: | :---: | :--- |
| **`P22_POP`** | Population totale (Socle) | **x 1** | `1 * P22_POP` | Demande de mobilité standard d'un résident métropolitain. |
| **`P22_POP1824`** | Jeunes & Étudiants (18-24 ans) | **x 3** | `+ (2 * P22_POP1824)` | Faible motorisation, budget contraint, flux massifs vers les campus et autres établissements supérieurs. |
| **`P22_POP1117`** | Collégiens & Lycéens (11-17 ans) | **x 3** | `+ (2 * P22_POP1117)` | Motorisation quasi nulle, forte dépendance aux parents, flux massifs vers les établissements primaires et secondaires. |
| **`GSEC16_26`** | Ouvriers (15 ans et +) | **x 2,5** | `+ (1.5 * GSEC16_26)` | Mobilité contrainte (pas de télétravail, horaires décalés, coût carburant). |
| **`P22_POP65P`** | Seniors (65 ans et +) | **x 2** | `+ (1 * P22_POP65P)` | Dépendance croissante aux transports pour l'accès aux soins/commerces. |
| **`GSEC40`** | Sans activité pro (15 ans et +) | **x 2** | `+ (1 * GSEC40)` | Proxy de précarité nécessitant un désenclavement vers l'emploi et les services. |

### C. Modèle Récepteur (`score_bpe`) : Stratification à 3 niveaux 
Plutôt que de pondérer manuellement près de 200 codes `TYPEQU`, l'algorithme exploite une structure séquentielle `CASE WHEN` en entonnoir (du code précis `TYPEQU` vers le sous-domaine `SDOM` puis le domaine `DOM`), après élimination des « faux positifs » :

| Niveau / Priorité SQL | Cible BPE (`TYPEQU` / `SDOM` / `DOM`) | Points | Justification urbaine & Arbitrages métiers |
| :--- | :--- | :---: | :--- |
| **1. Exclusions (Bruit)** | `SDOM = 'A4'` (BTP) et `TYPEQU` auto/logistique (`A133`, `A301-A303`, `B316`, `B326`, `E101`) | **0 pt** | Neutralisation des sièges d'artisans domiciliés, déchèteries, garages, stations-service et taxis qui ne génèrent aucun flux TC. |
| **2. Intermodalité lourde** | `TYPEQU IN ('E107', 'E108', 'E109')` | **150 pts** | Gares ferroviaires (nationale, régionale, locale) : rabattement multimodal. |
| **3. Locomotives urbaines** | `B104`, `D101-D107` ou `SDOM IN ('C3','C4','C5','C7')` | **100 pts** | Hypermarchés, Hôpitaux/Cliniques/Maternités, Lycées, Enseignement supérieur et résidences/restaurants CROUS. |
| **4. Pôles secondaires** | `TYPEQU IN ('B105', 'E102')` | **50 pts** | Supermarchés structurants et aérodrome. |
| **5. Centralités de quartier** | `SDOM IN ('C1', 'C2', 'C6', 'D1')` *(hors D101-D107)* | **30 pts** | Écoles, Collèges, Centres d'apprentissage (CFA/GRETA) et Centres/Maisons de santé pluridisciplinaires. |
| **6. Pôles intermédiaires** | `B103`, `SDOM = 'A1'` *(hors A133)* ou `DOM = 'F'` | **20 pts** | Services publics (Mairies, France Travail...), GSB, Sports, Loisirs et Culture. |
| **7. Santé libérale & Hôtels**| `DOM IN ('D', 'G')` *(hors D1)* | **10 pts** | Médecins, pharmacies, crèches, action sociale et hôtellerie (voyageurs captifs). |
| **8. Commerces de rue** | `A304` (Auto-écoles) ou `DOM = 'B'` *(hors B1)* | **5 pts** | Tissu commercial de proximité et auto-écoles (public jeune non motorisé). |
| **9. Services courants** | `ELSE` *(reste du domaine `A` : `A2`, `A5`)* | **2 pts** | Banques, bureaux de poste, coiffure, restauration rapide (effet cumulatif de mixité). |

*(La grille complète de pondération justifiée sur 11 pages est consultable dans [`/documentation/Grille_Ponderation_BPE.pdf`](documentation/Grille_Ponderation_BPE.pdf)).*

---

## 4. Premiers Résultats (Sortie SQLite — Top 10 Brut sur 117 IRIS)

L'exécution du script d'agrégation (`04_agregation_finale_iris.sql`) génère la table maîtresse [`SCORE_IRIS_ORLEANS.csv`](data_livrables/SCORE_IRIS_ORLEANS.csv). Voici les **10 premiers IRIS en volume brut** (avant pondération surfacique au km²) :

| Rang | Code IRIS | Commune | Nom de l'IRIS | Type | Pop. Totale | Nb Équip. | Score Émetteur | Score Récepteur | **Score TPS Brut** |
| :---: | :---: | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **1** | `453020101` | **Saran** | Centre | H | 7 016 | 363 | 13 486 | 2 207 | **15 693** |
| **2** | `452340702` | **Orléans** | Argonne-Champ Chardon-Fontaine-Nicotin | H | 6 068 | 141 | 11 311 | 873 | **12 184** |
| **3** | `452342103` | **Orléans** | Universités *(La Source)* | H | 2 498 | 126 | 7 933 | 3 956 | **11 889** |
| **4** | `451470401` | **Fleury-les-Aubrais** | Gare | H | 4 978 | 204 | 8 502 | 1 324 | **9 826** |
| **5** | `452340301` | **Orléans** | Carmes-République | H | 4 025 | 286 | 7 660 | 2 063 | **9 723** |
| **6** | `452320203` | **Olivet** | Larry | H | 3 962 | 213 | 7 294 | 2 039 | **9 333** |
| **7** | `453020104` | **Saran** | Sud-Ouest | H | 3 338 | 266 | 6 007 | 3 003 | **9 010** |
| **8** | `452350000` | **Ormes** | Ormes *(commune non irisée)* | Z | 4 341 | 116 | 7 788 | 735 | **8 523** |
| **9** | `452341401` | **Orléans** | Plantes-Dauphine | H | 3 955 | 126 | 7 218 | 1 206 | **8 424** |
| **10**| `452840101` | **Saint-Jean-de-Braye**| Puits de Ville-Centre Ville | H | 3 873 | 135 | 6 949 | 1 190 | **8 139** |

### Enseignements clefs pour la Phase 2 (QGIS) :
1. **Validation des polarités majeures :** Le modèle fait ressortir avec précision les grands générateurs métropolitains (le quartier *Argonne* à forte captivité sociale, le pôle *Universités* qui culmine à 3 956 points récepteurs, le pôle multimodal de *Fleury Gare*, l'hypercentre *Carmes-République* ou les pôles commerciaux de *Saran*).
2. **Nécessité de la pondération surfacique (Densité au km²) :** La présence en haut de classement de vastes polygones périurbains (comme *Saran Centre* avec 7 016 habitants ou la commune entière non-irisée d'*Ormes*) confirme notre hypothèse méthodologique : **un volume brut peut être élevé alors qu'il concerne une grande superficie ce qui risque de diluer l'efficacité d'une station de tramway (attractivité piétonne fixée à 800m)**. Le passage sous QGIS (`Score_Brut / $area`) permettra de révéler les véritables pôles de densité urbaine.

---

## 5. Structure du Dépôt

```text
├── data_livrables/
│   ├── SCORE_IRIS_ORLEANS.csv                         # Table maîtresse agrégée (117 IRIS avec le score TPS)
│   └── BPE_ORLEANS_TPS.csv                            # Équipements géolocalisés en Lambert 93 (Échelle Micro)
├── scripts_sql/
│   ├── 01_extraction_perimetre_orleans.sql            # Filtrage CTAS des 22 communes d'Orléans Métropole
│   ├── 02_scoring_emetteur_population.sql             # Calcul du score démographique pondéré (score_pop)
│   ├── 03_scoring_recepteur_equipements.sql           # Calcul du score infrastructurel pondéré (score_bpe)
│   └── 04_agregation_finale_iris.sql                  # Fusion autour des 117 IRIS et création du score TPS
├── documentation/
│   ├── Grille_Ponderation_BPE.pdf                     # Matrice complète de pondération des équipements (11 pages)
│   ├── Journal_de_Bord.md                             # Méthodologie détaillée, choix d'ingénierie et limites
│   ├── Ref_2000_NJTransit_Transit_Score_Report.pdf    # Rapport fondateur NJ TRANSIT (Marchwinski, 2000)
│   └── Ref_2008_TRR2063_DVRPC_Transit_Score_Model.pdf # Article scientifique de calibration (Lutin et al., 2008)
└── README.md
```
