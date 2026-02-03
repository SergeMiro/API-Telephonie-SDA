-- ============================================================================
-- SCRIPT: 05_indexes.sql
-- BASE: FIMLONSQL2.HN_FIMAINFO_CONFIG
-- DESCRIPTION: Création des index pour optimiser les performances
-- DATE: 03 février 2026
-- ============================================================================

USE HN_FIMAINFO_CONFIG;
GO

-- ============================================================================
-- INDEX SUR TEL_DID (Table principale)
-- ============================================================================

-- Index sur le numéro DID (recherche rapide par numéro)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_did' AND object_id = OBJECT_ID('TEL_DID'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_did]
    ON [dbo].[TEL_DID] ([did])
    INCLUDE ([indicatif_id], [statut_id], [client_id]);
    PRINT 'Index IX_TEL_DID_did créé';
END
GO

-- Index sur le format E.164 (recherche internationale)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_e164' AND object_id = OBJECT_ID('TEL_DID'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_e164]
    ON [dbo].[TEL_DID] ([did_format_e164])
    WHERE [did_format_e164] IS NOT NULL;
    PRINT 'Index IX_TEL_DID_e164 créé';
END
GO

-- Index sur client (liste des DID par client)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_client' AND object_id = OBJECT_ID('TEL_DID'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_client]
    ON [dbo].[TEL_DID] ([client_id])
    INCLUDE ([did], [statut_id], [type_id], [region_id])
    WHERE [client_id] IS NOT NULL;
    PRINT 'Index IX_TEL_DID_client créé';
END
GO

-- Index sur statut (filtrage par statut)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_statut' AND object_id = OBJECT_ID('TEL_DID'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_statut]
    ON [dbo].[TEL_DID] ([statut_id])
    INCLUDE ([did], [client_id], [operateur_id]);
    PRINT 'Index IX_TEL_DID_statut créé';
END
GO

-- Index sur opérateur (gestion par opérateur)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_operateur' AND object_id = OBJECT_ID('TEL_DID'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_operateur]
    ON [dbo].[TEL_DID] ([operateur_id])
    INCLUDE ([did], [statut_id], [client_id]);
    PRINT 'Index IX_TEL_DID_operateur créé';
END
GO

-- Index sur région (filtrage géographique)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_region' AND object_id = OBJECT_ID('TEL_DID'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_region]
    ON [dbo].[TEL_DID] ([region_id])
    INCLUDE ([did], [client_id], [statut_id])
    WHERE [region_id] IS NOT NULL;
    PRINT 'Index IX_TEL_DID_region créé';
END
GO

-- Index sur type de DID
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_type' AND object_id = OBJECT_ID('TEL_DID'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_type]
    ON [dbo].[TEL_DID] ([type_id])
    INCLUDE ([did], [client_id], [statut_id]);
    PRINT 'Index IX_TEL_DID_type créé';
END
GO

-- Index composite pour recherches fréquentes (client + statut)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_client_statut' AND object_id = OBJECT_ID('TEL_DID'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_client_statut]
    ON [dbo].[TEL_DID] ([client_id], [statut_id])
    INCLUDE ([did], [type_id], [region_id], [description]);
    PRINT 'Index IX_TEL_DID_client_statut créé';
END
GO

-- Index sur groupement
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_groupement' AND object_id = OBJECT_ID('TEL_DID'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_groupement]
    ON [dbo].[TEL_DID] ([groupement_id])
    WHERE [groupement_id] IS NOT NULL;
    PRINT 'Index IX_TEL_DID_groupement créé';
END
GO

-- Index sur actif (filtrage rapide des enregistrements actifs)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_actif' AND object_id = OBJECT_ID('TEL_DID'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_actif]
    ON [dbo].[TEL_DID] ([actif])
    WHERE [actif] = 1;
    PRINT 'Index IX_TEL_DID_actif créé';
END
GO

-- ============================================================================
-- INDEX SUR TEL_DID_VIRTUAL
-- ============================================================================

-- Index sur DID (recherche de campagnes par numéro)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_VIRTUAL_did' AND object_id = OBJECT_ID('TEL_DID_VIRTUAL'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_VIRTUAL_did]
    ON [dbo].[TEL_DID_VIRTUAL] ([did_id])
    INCLUDE ([campaign_id], [config_id], [actif]);
    PRINT 'Index IX_TEL_DID_VIRTUAL_did créé';
END
GO

-- Index sur campagne (liste des DID par campagne)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_VIRTUAL_campaign' AND object_id = OBJECT_ID('TEL_DID_VIRTUAL'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_VIRTUAL_campaign]
    ON [dbo].[TEL_DID_VIRTUAL] ([campaign_id])
    INCLUDE ([did_id], [config_id], [priorite], [actif]);
    PRINT 'Index IX_TEL_DID_VIRTUAL_campaign créé';
END
GO

-- Index composite pour recherche d'affectations actives
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_VIRTUAL_actif' AND object_id = OBJECT_ID('TEL_DID_VIRTUAL'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_VIRTUAL_actif]
    ON [dbo].[TEL_DID_VIRTUAL] ([actif], [date_fin])
    INCLUDE ([did_id], [campaign_id])
    WHERE [actif] = 1;
    PRINT 'Index IX_TEL_DID_VIRTUAL_actif créé';
END
GO

-- ============================================================================
-- INDEX SUR TEL_DID_COMMANDE
-- ============================================================================

-- Index sur référence (recherche rapide par référence)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_COMMANDE_reference' AND object_id = OBJECT_ID('TEL_DID_COMMANDE'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_COMMANDE_reference]
    ON [dbo].[TEL_DID_COMMANDE] ([reference]);
    PRINT 'Index IX_TEL_DID_COMMANDE_reference créé';
END
GO

-- Index sur client (commandes par client)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_COMMANDE_client' AND object_id = OBJECT_ID('TEL_DID_COMMANDE'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_COMMANDE_client]
    ON [dbo].[TEL_DID_COMMANDE] ([client_id])
    INCLUDE ([reference], [statut_id], [date_creation], [quantite]);
    PRINT 'Index IX_TEL_DID_COMMANDE_client créé';
END
GO

-- Index sur statut (commandes par statut)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_COMMANDE_statut' AND object_id = OBJECT_ID('TEL_DID_COMMANDE'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_COMMANDE_statut]
    ON [dbo].[TEL_DID_COMMANDE] ([statut_id])
    INCLUDE ([reference], [client_id], [date_creation], [urgence]);
    PRINT 'Index IX_TEL_DID_COMMANDE_statut créé';
END
GO

-- Index sur urgence (tri par priorité)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_COMMANDE_urgence' AND object_id = OBJECT_ID('TEL_DID_COMMANDE'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_COMMANDE_urgence]
    ON [dbo].[TEL_DID_COMMANDE] ([urgence], [date_souhaitee])
    INCLUDE ([reference], [statut_id], [client_id]);
    PRINT 'Index IX_TEL_DID_COMMANDE_urgence créé';
END
GO

-- Index sur date création (historique)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_COMMANDE_date' AND object_id = OBJECT_ID('TEL_DID_COMMANDE'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_COMMANDE_date]
    ON [dbo].[TEL_DID_COMMANDE] ([date_creation] DESC)
    INCLUDE ([reference], [client_id], [statut_id]);
    PRINT 'Index IX_TEL_DID_COMMANDE_date créé';
END
GO

-- ============================================================================
-- INDEX SUR TEL_DID_HISTORIQUE
-- ============================================================================

-- Index sur DID (historique par numéro)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_HISTORIQUE_did' AND object_id = OBJECT_ID('TEL_DID_HISTORIQUE'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_HISTORIQUE_did]
    ON [dbo].[TEL_DID_HISTORIQUE] ([did_id], [date_action] DESC);
    PRINT 'Index IX_TEL_DID_HISTORIQUE_did créé';
END
GO

-- Index sur date (recherche temporelle)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_HISTORIQUE_date' AND object_id = OBJECT_ID('TEL_DID_HISTORIQUE'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_HISTORIQUE_date]
    ON [dbo].[TEL_DID_HISTORIQUE] ([date_action] DESC)
    INCLUDE ([did_id], [action], [champ_modifie]);
    PRINT 'Index IX_TEL_DID_HISTORIQUE_date créé';
END
GO

-- ============================================================================
-- INDEX SUR TABLES DE RÉFÉRENCE
-- ============================================================================

-- Index sur TEL_REGION (indicatif)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_REGION_indicatif' AND object_id = OBJECT_ID('TEL_REGION'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_REGION_indicatif]
    ON [dbo].[TEL_REGION] ([indicatif_id])
    INCLUDE ([code], [libelle], [prefixe]);
    PRINT 'Index IX_TEL_REGION_indicatif créé';
END
GO

-- Index sur TEL_GROUPEMENT (client)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_GROUPEMENT_client' AND object_id = OBJECT_ID('TEL_GROUPEMENT'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_GROUPEMENT_client]
    ON [dbo].[TEL_GROUPEMENT] ([client_id])
    INCLUDE ([code], [libelle]);
    PRINT 'Index IX_TEL_GROUPEMENT_client créé';
END
GO

-- Index sur TEL_CAMPAIGN (client)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_CAMPAIGN_client' AND object_id = OBJECT_ID('TEL_CAMPAIGN'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_CAMPAIGN_client]
    ON [dbo].[TEL_CAMPAIGN] ([client_id])
    INCLUDE ([code], [nom], [hermes_id]);
    PRINT 'Index IX_TEL_CAMPAIGN_client créé';
END
GO

-- ============================================================================
-- INDEX SUR TEL_DID_COMMANDE_LIGNE
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_COMMANDE_LIGNE_commande' AND object_id = OBJECT_ID('TEL_DID_COMMANDE_LIGNE'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_COMMANDE_LIGNE_commande]
    ON [dbo].[TEL_DID_COMMANDE_LIGNE] ([commande_id])
    INCLUDE ([did_id]);
    PRINT 'Index IX_TEL_DID_COMMANDE_LIGNE_commande créé';
END
GO

-- ============================================================================
-- INDEX SUR TEL_DID_COMMANDE_COMMENTAIRE
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TEL_DID_COMMANDE_COMMENTAIRE_commande' AND object_id = OBJECT_ID('TEL_DID_COMMANDE_COMMENTAIRE'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TEL_DID_COMMANDE_COMMENTAIRE_commande]
    ON [dbo].[TEL_DID_COMMANDE_COMMENTAIRE] ([commande_id], [date_creation] DESC);
    PRINT 'Index IX_TEL_DID_COMMANDE_COMMENTAIRE_commande créé';
END
GO

PRINT '============================================';
PRINT 'Script 05_indexes.sql terminé';
PRINT '============================================';
GO
