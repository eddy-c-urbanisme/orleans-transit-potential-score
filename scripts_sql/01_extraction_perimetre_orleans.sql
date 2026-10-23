-- ÉTAPE 2.1 (Volet A) : BPE
-- OBJECTIF : Isoler le territoire d'étude et alléger la base de données.
-- Utilisation de la méthode CTAS (Create Table As Select) pour extraire 
-- de manière non-destructive les équipements de la métropole d'Orléans 
-- depuis la base nationale de 2,9 millions de lignes.

CREATE TABLE IF NOT EXISTS BPE_ORLEANS AS
SELECT *
FROM BPE25
WHERE DEPCOM IN ('45034', '45046', '45072', '45075', '45089', '45100', '45147', '45169', '45194', '45196', '45232', '45234', '45235', '45272', '45274', '45282', '45284', '45285', '45286', '45298', '45302', '45308');

-- ÉTAPE 2.1 (Volet B) : Références IRIS
-- OBJECTIF : Utilisation de la méthode CTAS (Create Table As Select)
-- pour isoler correctement l'ensemble des IRIS et communes non irisées d'Orléans Métropole

CREATE TABLE IF NOT EXISTS REF_IRIS_ORLEANS AS
SELECT *
FROM REF_IRIS
WHERE code_dpt_com IN ('45034', '45046', '45072', '45075', '45089', '45100', '45147', '45169', '45194', '45196', '45232', '45234', '45235', '45272', '45274', '45282', '45284', '45285', '45286', '45298', '45302', '45308');

-- ÉTAPE 2.1 (Volet C) : Population

CREATE TABLE IF NOT EXISTS POP_ORLEANS AS
SELECT *
FROM POPULATION_FRANCE
WHERE POPULATION_FRANCE.COM IN ('45034', '45046', '45072', '45075', '45089', '45100', '45147', '45169', '45194', '45196', '45232', '45234', '45235', '45272', '45274', '45282', '45284', '45285', '45286', '45298', '45302', '45308');

 
