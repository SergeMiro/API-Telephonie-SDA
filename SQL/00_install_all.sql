-- ============================================================================
-- SCRIPT: 00_install_all.sql
-- BASE: FIMLONSQL2.HN_FIMAINFO_CONFIG
-- DESCRIPTION: Script principal d'installation - exécute tous les scripts
-- DATE: 03 février 2026
-- ============================================================================
--
-- ORDRE D'EXÉCUTION:
-- 1. 01_tables_reference.sql  - Tables de référence (lookup tables)
-- 2. 02_table_did.sql         - Table principale DID
-- 3. 03_tables_virtual_config.sql - Tables DID_VIRTUAL et DID_CONFIG
-- 4. 04_table_commande.sql    - Tables de gestion des commandes
-- 5. 05_indexes.sql           - Index pour optimisation
-- 6. 06_views.sql             - Vues pour l'API
--
-- PRÉREQUIS:
-- - Base de données HN_FIMAINFO_CONFIG existante
-- - Droits de création de tables, vues, triggers, séquences
--
-- UTILISATION:
-- Option 1: Exécuter ce fichier depuis SSMS (ajuster les chemins :r)
-- Option 2: Exécuter chaque script individuellement dans l'ordre
--
-- ============================================================================

USE HN_FIMAINFO_CONFIG;
GO

PRINT '============================================';
PRINT 'INSTALLATION SCHEMA TELEPHONIE DID';
PRINT 'Date: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '============================================';
GO

-- Note: Les commandes :r ci-dessous fonctionnent en mode SQLCMD
-- Si vous n'êtes pas en mode SQLCMD, exécutez chaque script séparément

/*
-- Mode SQLCMD (décommenter si utilisé en mode SQLCMD):
:r "01_tables_reference.sql"
:r "02_table_did.sql"
:r "03_tables_virtual_config.sql"
:r "04_table_commande.sql"
:r "05_indexes.sql"
:r "06_views.sql"
*/

PRINT '';
PRINT '============================================';
PRINT 'Pour installer manuellement, exécutez dans l''ordre:';
PRINT '1. 01_tables_reference.sql';
PRINT '2. 02_table_did.sql';
PRINT '3. 03_tables_virtual_config.sql';
PRINT '4. 04_table_commande.sql';
PRINT '5. 05_indexes.sql';
PRINT '6. 06_views.sql';
PRINT '============================================';
GO

-- ============================================================================
-- VÉRIFICATION POST-INSTALLATION
-- ============================================================================

PRINT '';
PRINT 'VÉRIFICATION DES OBJETS CRÉÉS:';
PRINT '------------------------------';

-- Tables
SELECT 'TABLES' AS [Type], COUNT(*) AS [Nombre]
FROM sys.tables
WHERE name LIKE 'TEL_%';

-- Vues
SELECT 'VUES' AS [Type], COUNT(*) AS [Nombre]
FROM sys.views
WHERE name LIKE 'V_TEL_%';

-- Index (hors PK et UK)
SELECT 'INDEX' AS [Type], COUNT(*) AS [Nombre]
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE t.name LIKE 'TEL_%'
  AND i.name LIKE 'IX_%';

-- Triggers
SELECT 'TRIGGERS' AS [Type], COUNT(*) AS [Nombre]
FROM sys.triggers tr
INNER JOIN sys.tables t ON tr.parent_id = t.object_id
WHERE t.name LIKE 'TEL_%';

-- Liste des tables créées
PRINT '';
PRINT 'TABLES CRÉÉES:';
SELECT name AS [Table]
FROM sys.tables
WHERE name LIKE 'TEL_%'
ORDER BY name;

-- Liste des vues créées
PRINT '';
PRINT 'VUES CRÉÉES:';
SELECT name AS [Vue]
FROM sys.views
WHERE name LIKE 'V_TEL_%'
ORDER BY name;

GO
