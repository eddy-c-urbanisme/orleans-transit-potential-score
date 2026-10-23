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
