-- ÉTAPE 2.3 (Volet A) : Recréation propre si màj et calcul du Score Émetteur
DROP TABLE IF EXISTS POP_ORLEANS_TPS;

CREATE TABLE POP_ORLEANS_TPS AS
SELECT
    pop.IRIS, 
    pop.P22_POP, 
    pop.P22_POP1117, 
    pop.P22_POP1824, 
    pop.P22_POP65P, 
    pop.C22_POP15P_STAT_GSEC16_26, 
    pop.C22_POP15P_STAT_GSEC40,
    -- Calcul intégré du Score Émetteur brut (Socle 1 pt + Bonus captifs)
    ROUND(
    (P22_POP * 1) + 
    (P22_POP1824 * 2) +                  -- Poids total x3 (1 de base + 2 bonus)
    (P22_POP1117 * 2) +                  -- Poids total x3 (1 de base + 2 bonus)
    (P22_POP65P * 1) +                   -- Poids total x2 (1 de base + 1 bonus)
    (C22_POP15P_STAT_GSEC16_26 * 1.5) +  -- Poids total x2.5 (1 de base + 1.5 bonus)
    (C22_POP15P_STAT_GSEC40 * 1),        -- Poids total x2 (1 de base + 1 bonus)
0) AS score_pop
FROM POP_ORLEANS AS pop;

 -- ÉTAPE 2.3 (Volet B) : Enrichissement et calcul intégré du Score Récepteur (Attractivité BPE)
DROP TABLE IF EXISTS BPE_ORLEANS_TPS;

CREATE TABLE BPE_ORLEANS_TPS AS
SELECT
    bpe.DCIRIS,                 -- Clé de jointure IRIS (9 chiffres)
    bpe.NOMRS,                  -- Nom de l'équipement
    bpe.TYPEQU,                 -- Code équipement (Niveau 1)
    passage.LIBELLE_TYPEQU,     -- Libellé équipement
    passage.SDOM,               -- Code sous-domaine (Niveau 2)
    passage.LIBELLE_SDOM,       -- Libellé sous-domaine
    passage.DOM,                -- Code domaine (Niveau 3)
    passage.LIBELLE_DOM,        -- Libellé domaine
    bpe.CAPACITE,               -- Capacité (conservée à titre informatif pour QGIS/Power BI)
    bpe.NBSALLES,               -- Nombre de salles (informatif)
    bpe.LAMBERT_X,              -- Coordonnée X (Lambert 93 - mètres)
    bpe.LAMBERT_Y,              -- Coordonnée Y (Lambert 93 - mètres)
    iris.lib_com,               -- Nom de la commune
    iris.lib_iris,              -- Nom du quartier IRIS

    -- Calcul du Score Récepteur selon la grille de pondération V2
    CASE
        -- 1. EXCLUSIONS (0 pt) : Déchèteries, services auto (hors auto-école), BTP, stations-service, bornes, taxis
        WHEN bpe.TYPEQU IN ('A133', 'A301', 'A302', 'A303', 'B316', 'B326', 'E101') 
             OR passage.SDOM = 'A4' THEN 0

        -- 2. INTERMODALITÉ LOURDE (150 pts) : Gares ferroviaires (nationale, régionale, locale)
        WHEN bpe.TYPEQU IN ('E107', 'E108', 'E109') THEN 150

        -- 3. LOCOMOTIVES URBAINES (100 pts) : Hypermarchés, Lycées, Enseignement Supérieur, CROUS, Hôpitaux/Maternités
        WHEN bpe.TYPEQU IN ('B104', 'D101', 'D102', 'D103', 'D104', 'D105', 'D106', 'D107') 
             OR passage.SDOM IN ('C3', 'C4', 'C5', 'C7') THEN 100

        -- 4. PÔLES SECONDAIRES (50 pts) : Supermarchés et Aéroport
        WHEN bpe.TYPEQU IN ('B105', 'E102') THEN 50

        -- 5. CENTRALITÉS DE QUARTIER (30 pts) : Écoles, Collèges, Apprentissage (C6) et Centres de santé (D108 à D115)
        WHEN passage.SDOM IN ('C1', 'C2', 'C6', 'D1') THEN 30

        -- 6. ÉQUIPEMENTS INTERMÉDIAIRES (20 pts) : Services publics (reste A1), GSB (B103), Sports, Loisirs et Culture (DOM F)
        WHEN bpe.TYPEQU = 'B103' 
             OR passage.SDOM = 'A1' 
             OR passage.DOM = 'F' THEN 20

        -- 7. SANTÉ LIBÉRALE, ACTION SOCIALE & TOURISME (10 pts) : Reste du domaine D (D2 à D7) et Domaine G (G1)
        WHEN passage.DOM IN ('D', 'G') THEN 10

        -- 8. COMMERCES DE PROXIMITÉ & AUTO-ÉCOLES (5 pts) : Auto-écoles (A304) et reste des commerces (B2, B3)
        WHEN bpe.TYPEQU = 'A304' 
             OR passage.DOM = 'B' THEN 5

        -- 9. SERVICES COURANTS AUX PARTICULIERS (2 pts) : Banques, Poste, Coiffure, Restauration (A2, A5)
        ELSE 2
    END AS score_bpe

FROM BPE_ORLEANS AS bpe
LEFT JOIN BPE25_table_passage AS passage
    ON bpe.TYPEQU = passage.TYPEQU
LEFT JOIN REF_IRIS_ORLEANS AS iris
    ON bpe.DCIRIS = iris.Code_Iris;
