-- ============================================================================
-- SCRIPT: 06_views.sql
-- BASE: FIMLONSQL2.HN_FIMAINFO_CONFIG
-- DESCRIPTION: Vues SQL pour faciliter les requêtes API
-- DATE: 03 février 2026
-- ============================================================================

USE HN_FIMAINFO_CONFIG;
GO

-- ============================================================================
-- VUE: V_TEL_DID_COMPLET
-- Description: Vue complète des DID avec toutes les informations jointes
-- Usage: Liste principale des DID pour l'interface
-- ============================================================================
IF EXISTS (SELECT * FROM sys.views WHERE name = 'V_TEL_DID_COMPLET')
    DROP VIEW [dbo].[V_TEL_DID_COMPLET];
GO

CREATE VIEW [dbo].[V_TEL_DID_COMPLET]
AS
SELECT
    -- Identifiant
    d.[id],
    d.[did],
    d.[did_format_e164],

    -- Indicatif
    d.[indicatif_id],
    i.[code] AS [indicatif_code],
    i.[indicatif] AS [indicatif_prefixe],
    i.[libelle] AS [indicatif_pays],

    -- Opérateur
    d.[operateur_id],
    op.[code] AS [operateur_code],
    op.[nom] AS [operateur_nom],

    -- Type
    d.[type_id],
    t.[code] AS [type_code],
    t.[libelle] AS [type_libelle],

    -- Région
    d.[region_id],
    r.[code] AS [region_code],
    r.[libelle] AS [region_libelle],
    r.[prefixe] AS [region_prefixe],

    -- Équipement
    d.[equipement_id],
    eq.[code] AS [equipement_code],
    eq.[nom] AS [equipement_nom],

    -- Client
    d.[client_id],
    c.[code] AS [client_code],
    c.[nom] AS [client_nom],

    -- Groupement
    d.[groupement_id],
    g.[code] AS [groupement_code],
    g.[libelle] AS [groupement_libelle],

    -- Cloud
    d.[cloud_id],
    cl.[code] AS [cloud_code],
    cl.[nom] AS [cloud_nom],

    -- Statut
    d.[statut_id],
    s.[code] AS [statut_code],
    s.[libelle] AS [statut_libelle],
    s.[couleur] AS [statut_couleur],

    -- Informations
    d.[description],
    d.[reference_externe],
    d.[date_acquisition],
    d.[date_activation],
    d.[date_resiliation],
    d.[cout_mensuel],
    d.[notes],

    -- Métadonnées
    d.[actif],
    d.[created_by],
    d.[modified_by],
    d.[date_creation],
    d.[date_modification]

FROM [dbo].[TEL_DID] d
LEFT JOIN [dbo].[TEL_INDICATIF] i ON d.[indicatif_id] = i.[id]
LEFT JOIN [dbo].[TEL_OPERATEUR] op ON d.[operateur_id] = op.[id]
LEFT JOIN [dbo].[TEL_TYPE_DID] t ON d.[type_id] = t.[id]
LEFT JOIN [dbo].[TEL_REGION] r ON d.[region_id] = r.[id]
LEFT JOIN [dbo].[TEL_EQUIPEMENT] eq ON d.[equipement_id] = eq.[id]
LEFT JOIN [dbo].[TEL_CLIENT] c ON d.[client_id] = c.[id]
LEFT JOIN [dbo].[TEL_GROUPEMENT] g ON d.[groupement_id] = g.[id]
LEFT JOIN [dbo].[TEL_CLOUD] cl ON d.[cloud_id] = cl.[id]
LEFT JOIN [dbo].[TEL_STATUT_DID] s ON d.[statut_id] = s.[id];
GO

PRINT 'Vue V_TEL_DID_COMPLET créée avec succès';
GO

-- ============================================================================
-- VUE: V_TEL_DID_DISPONIBLE
-- Description: DID disponibles (non affectés à une campagne)
-- Usage: Liste des numéros disponibles pour affectation
-- ============================================================================
IF EXISTS (SELECT * FROM sys.views WHERE name = 'V_TEL_DID_DISPONIBLE')
    DROP VIEW [dbo].[V_TEL_DID_DISPONIBLE];
GO

CREATE VIEW [dbo].[V_TEL_DID_DISPONIBLE]
AS
SELECT
    d.[id],
    d.[did],
    d.[did_format_e164],
    d.[indicatif_code],
    d.[indicatif_pays],
    d.[operateur_nom],
    d.[type_libelle],
    d.[region_libelle],
    d.[client_id],
    d.[client_code],
    d.[client_nom],
    d.[groupement_libelle],
    d.[statut_libelle],
    d.[description],
    d.[date_creation]
FROM [dbo].[V_TEL_DID_COMPLET] d
WHERE d.[statut_code] = 'DISPONIBLE'
  AND d.[actif] = 1;
GO

PRINT 'Vue V_TEL_DID_DISPONIBLE créée avec succès';
GO

-- ============================================================================
-- VUE: V_TEL_DID_PAR_CLIENT
-- Description: Résumé des DID par client avec compteurs
-- Usage: Dashboard et statistiques
-- ============================================================================
IF EXISTS (SELECT * FROM sys.views WHERE name = 'V_TEL_DID_PAR_CLIENT')
    DROP VIEW [dbo].[V_TEL_DID_PAR_CLIENT];
GO

CREATE VIEW [dbo].[V_TEL_DID_PAR_CLIENT]
AS
SELECT
    c.[id] AS [client_id],
    c.[code] AS [client_code],
    c.[nom] AS [client_nom],
    COUNT(d.[id]) AS [total_did],
    SUM(CASE WHEN s.[code] = 'COMMANDE' THEN 1 ELSE 0 END) AS [nb_commandes],
    SUM(CASE WHEN s.[code] = 'DISPONIBLE' THEN 1 ELSE 0 END) AS [nb_disponibles],
    SUM(CASE WHEN s.[code] = 'AFFECTE' THEN 1 ELSE 0 END) AS [nb_affectes],
    SUM(CASE WHEN s.[code] = 'UTILISE' THEN 1 ELSE 0 END) AS [nb_utilises],
    SUM(CASE WHEN s.[code] = 'RESILIE' THEN 1 ELSE 0 END) AS [nb_resilies]
FROM [dbo].[TEL_CLIENT] c
LEFT JOIN [dbo].[TEL_DID] d ON c.[id] = d.[client_id] AND d.[actif] = 1
LEFT JOIN [dbo].[TEL_STATUT_DID] s ON d.[statut_id] = s.[id]
WHERE c.[actif] = 1
GROUP BY c.[id], c.[code], c.[nom];
GO

PRINT 'Vue V_TEL_DID_PAR_CLIENT créée avec succès';
GO

-- ============================================================================
-- VUE: V_TEL_DID_PAR_REGION
-- Description: Répartition des DID par région
-- Usage: Analyse géographique
-- ============================================================================
IF EXISTS (SELECT * FROM sys.views WHERE name = 'V_TEL_DID_PAR_REGION')
    DROP VIEW [dbo].[V_TEL_DID_PAR_REGION];
GO

CREATE VIEW [dbo].[V_TEL_DID_PAR_REGION]
AS
SELECT
    r.[id] AS [region_id],
    r.[code] AS [region_code],
    r.[libelle] AS [region_libelle],
    r.[prefixe] AS [region_prefixe],
    i.[code] AS [indicatif_code],
    i.[libelle] AS [indicatif_pays],
    COUNT(d.[id]) AS [total_did],
    SUM(CASE WHEN s.[code] = 'DISPONIBLE' THEN 1 ELSE 0 END) AS [nb_disponibles],
    SUM(CASE WHEN s.[code] = 'UTILISE' THEN 1 ELSE 0 END) AS [nb_utilises]
FROM [dbo].[TEL_REGION] r
INNER JOIN [dbo].[TEL_INDICATIF] i ON r.[indicatif_id] = i.[id]
LEFT JOIN [dbo].[TEL_DID] d ON r.[id] = d.[region_id] AND d.[actif] = 1
LEFT JOIN [dbo].[TEL_STATUT_DID] s ON d.[statut_id] = s.[id]
WHERE r.[actif] = 1
GROUP BY r.[id], r.[code], r.[libelle], r.[prefixe], i.[code], i.[libelle];
GO

PRINT 'Vue V_TEL_DID_PAR_REGION créée avec succès';
GO

-- ============================================================================
-- VUE: V_TEL_DID_VIRTUAL_COMPLET
-- Description: Affectations DID-Campagne avec détails
-- Usage: Gestion des affectations Hermes
-- ============================================================================
IF EXISTS (SELECT * FROM sys.views WHERE name = 'V_TEL_DID_VIRTUAL_COMPLET')
    DROP VIEW [dbo].[V_TEL_DID_VIRTUAL_COMPLET];
GO

CREATE VIEW [dbo].[V_TEL_DID_VIRTUAL_COMPLET]
AS
SELECT
    dv.[id],
    dv.[did_id],
    d.[did],
    d.[did_format_e164],
    dv.[campaign_id],
    cp.[code] AS [campaign_code],
    cp.[nom] AS [campaign_nom],
    cp.[hermes_id],
    dv.[config_id],
    cfg.[code] AS [config_code],
    cfg.[nom] AS [config_nom],
    cfg.[config] AS [config_json],
    dv.[alias],
    dv.[priorite],
    dv.[date_debut],
    dv.[date_fin],
    dv.[entrant],
    dv.[sortant],
    c.[id] AS [client_id],
    c.[code] AS [client_code],
    c.[nom] AS [client_nom],
    dv.[actif],
    dv.[date_creation],
    dv.[date_modification],
    -- Indicateur si l'affectation est courante
    CASE
        WHEN dv.[actif] = 1
         AND dv.[date_debut] <= GETDATE()
         AND (dv.[date_fin] IS NULL OR dv.[date_fin] >= GETDATE())
        THEN 1
        ELSE 0
    END AS [is_current]
FROM [dbo].[TEL_DID_VIRTUAL] dv
INNER JOIN [dbo].[TEL_DID] d ON dv.[did_id] = d.[id]
INNER JOIN [dbo].[TEL_CAMPAIGN] cp ON dv.[campaign_id] = cp.[id]
LEFT JOIN [dbo].[TEL_DID_CONFIG] cfg ON dv.[config_id] = cfg.[id]
LEFT JOIN [dbo].[TEL_CLIENT] c ON cp.[client_id] = c.[id];
GO

PRINT 'Vue V_TEL_DID_VIRTUAL_COMPLET créée avec succès';
GO

-- ============================================================================
-- VUE: V_TEL_COMMANDE_COMPLET
-- Description: Commandes avec détails complets
-- Usage: Gestion des demandes de commande
-- ============================================================================
IF EXISTS (SELECT * FROM sys.views WHERE name = 'V_TEL_COMMANDE_COMPLET')
    DROP VIEW [dbo].[V_TEL_COMMANDE_COMPLET];
GO

CREATE VIEW [dbo].[V_TEL_COMMANDE_COMPLET]
AS
SELECT
    cmd.[id],
    cmd.[reference],

    -- Client
    cmd.[client_id],
    c.[code] AS [client_code],
    c.[nom] AS [client_nom],

    -- Groupement
    cmd.[groupement_id],
    g.[libelle] AS [groupement_libelle],

    -- Demandeur
    cmd.[demandeur_nom],
    cmd.[demandeur_email],
    cmd.[demandeur_tel],

    -- Opérateur
    cmd.[operateur_id],
    op.[nom] AS [operateur_nom],

    -- Type DID
    cmd.[type_did_id],
    t.[code] AS [type_code],
    t.[libelle] AS [type_libelle],

    -- Région
    cmd.[region_id],
    r.[libelle] AS [region_libelle],
    r.[prefixe] AS [region_prefixe],

    -- Détails
    cmd.[quantite],
    cmd.[prefixe_souhaite],
    cmd.[motif],
    cmd.[urgence],
    cmd.[date_souhaitee],

    -- Statut
    cmd.[statut_id],
    s.[code] AS [statut_code],
    s.[libelle] AS [statut_libelle],
    s.[couleur] AS [statut_couleur],

    -- Validation
    cmd.[valideur_nom],
    cmd.[date_validation],
    cmd.[commentaire_validation],
    cmd.[reference_operateur],
    cmd.[date_livraison],

    -- Compteur DID livrés
    (SELECT COUNT(*) FROM [dbo].[TEL_DID_COMMANDE_LIGNE] l WHERE l.[commande_id] = cmd.[id]) AS [nb_did_livres],

    -- Métadonnées
    cmd.[actif],
    cmd.[created_by],
    cmd.[date_creation],
    cmd.[date_modification]

FROM [dbo].[TEL_DID_COMMANDE] cmd
LEFT JOIN [dbo].[TEL_CLIENT] c ON cmd.[client_id] = c.[id]
LEFT JOIN [dbo].[TEL_GROUPEMENT] g ON cmd.[groupement_id] = g.[id]
LEFT JOIN [dbo].[TEL_OPERATEUR] op ON cmd.[operateur_id] = op.[id]
LEFT JOIN [dbo].[TEL_TYPE_DID] t ON cmd.[type_did_id] = t.[id]
LEFT JOIN [dbo].[TEL_REGION] r ON cmd.[region_id] = r.[id]
LEFT JOIN [dbo].[TEL_STATUT_COMMANDE] s ON cmd.[statut_id] = s.[id];
GO

PRINT 'Vue V_TEL_COMMANDE_COMPLET créée avec succès';
GO

-- ============================================================================
-- VUE: V_TEL_COMMANDE_EN_ATTENTE
-- Description: Commandes en attente de traitement
-- Usage: Dashboard admin - commandes à traiter
-- ============================================================================
IF EXISTS (SELECT * FROM sys.views WHERE name = 'V_TEL_COMMANDE_EN_ATTENTE')
    DROP VIEW [dbo].[V_TEL_COMMANDE_EN_ATTENTE];
GO

CREATE VIEW [dbo].[V_TEL_COMMANDE_EN_ATTENTE]
AS
SELECT
    cmd.[id],
    cmd.[reference],
    cmd.[client_nom],
    cmd.[demandeur_nom],
    cmd.[demandeur_email],
    cmd.[type_libelle],
    cmd.[region_libelle],
    cmd.[quantite],
    cmd.[urgence],
    cmd.[date_souhaitee],
    cmd.[statut_code],
    cmd.[statut_libelle],
    cmd.[statut_couleur],
    cmd.[date_creation],
    -- Délai en jours depuis la création
    DATEDIFF(DAY, cmd.[date_creation], GETDATE()) AS [jours_attente]
FROM [dbo].[V_TEL_COMMANDE_COMPLET] cmd
WHERE cmd.[statut_code] IN ('SOUMISE', 'VALIDEE', 'EN_COURS')
  AND cmd.[actif] = 1;
GO

PRINT 'Vue V_TEL_COMMANDE_EN_ATTENTE créée avec succès';
GO

-- ============================================================================
-- VUE: V_TEL_STATISTIQUES_GLOBALES
-- Description: Statistiques globales pour dashboard
-- Usage: Page d'accueil admin
-- ============================================================================
IF EXISTS (SELECT * FROM sys.views WHERE name = 'V_TEL_STATISTIQUES_GLOBALES')
    DROP VIEW [dbo].[V_TEL_STATISTIQUES_GLOBALES];
GO

CREATE VIEW [dbo].[V_TEL_STATISTIQUES_GLOBALES]
AS
SELECT
    (SELECT COUNT(*) FROM [dbo].[TEL_DID] WHERE [actif] = 1) AS [total_did],
    (SELECT COUNT(*) FROM [dbo].[TEL_DID] d
     INNER JOIN [dbo].[TEL_STATUT_DID] s ON d.[statut_id] = s.[id]
     WHERE d.[actif] = 1 AND s.[code] = 'UTILISE') AS [did_utilises],
    (SELECT COUNT(*) FROM [dbo].[TEL_DID] d
     INNER JOIN [dbo].[TEL_STATUT_DID] s ON d.[statut_id] = s.[id]
     WHERE d.[actif] = 1 AND s.[code] = 'DISPONIBLE') AS [did_disponibles],
    (SELECT COUNT(*) FROM [dbo].[TEL_DID] d
     INNER JOIN [dbo].[TEL_STATUT_DID] s ON d.[statut_id] = s.[id]
     WHERE d.[actif] = 1 AND s.[code] = 'COMMANDE') AS [did_commandes],
    (SELECT COUNT(*) FROM [dbo].[TEL_CLIENT] WHERE [actif] = 1) AS [total_clients],
    (SELECT COUNT(*) FROM [dbo].[TEL_CAMPAIGN] WHERE [actif] = 1) AS [total_campaigns],
    (SELECT COUNT(*) FROM [dbo].[TEL_DID_COMMANDE] cmd
     INNER JOIN [dbo].[TEL_STATUT_COMMANDE] s ON cmd.[statut_id] = s.[id]
     WHERE cmd.[actif] = 1 AND s.[code] IN ('SOUMISE', 'VALIDEE', 'EN_COURS')) AS [commandes_en_cours];
GO

PRINT 'Vue V_TEL_STATISTIQUES_GLOBALES créée avec succès';
GO

-- ============================================================================
-- VUE: V_TEL_DID_HISTORIQUE_COMPLET
-- Description: Historique avec détails pour audit
-- Usage: Traçabilité des modifications
-- ============================================================================
IF EXISTS (SELECT * FROM sys.views WHERE name = 'V_TEL_DID_HISTORIQUE_COMPLET')
    DROP VIEW [dbo].[V_TEL_DID_HISTORIQUE_COMPLET];
GO

CREATE VIEW [dbo].[V_TEL_DID_HISTORIQUE_COMPLET]
AS
SELECT
    h.[id],
    h.[did_id],
    d.[did],
    d.[did_format_e164],
    c.[nom] AS [client_nom],
    h.[action],
    h.[champ_modifie],
    h.[ancienne_valeur],
    h.[nouvelle_valeur],
    -- Libellés pour statut_id
    CASE
        WHEN h.[champ_modifie] = 'statut_id' THEN
            (SELECT [libelle] FROM [dbo].[TEL_STATUT_DID] WHERE [id] = TRY_CAST(h.[ancienne_valeur] AS INT))
        ELSE h.[ancienne_valeur]
    END AS [ancienne_valeur_libelle],
    CASE
        WHEN h.[champ_modifie] = 'statut_id' THEN
            (SELECT [libelle] FROM [dbo].[TEL_STATUT_DID] WHERE [id] = TRY_CAST(h.[nouvelle_valeur] AS INT))
        ELSE h.[nouvelle_valeur]
    END AS [nouvelle_valeur_libelle],
    h.[utilisateur],
    h.[date_action]
FROM [dbo].[TEL_DID_HISTORIQUE] h
INNER JOIN [dbo].[TEL_DID] d ON h.[did_id] = d.[id]
LEFT JOIN [dbo].[TEL_CLIENT] c ON d.[client_id] = c.[id];
GO

PRINT 'Vue V_TEL_DID_HISTORIQUE_COMPLET créée avec succès';
GO

-- ============================================================================
-- VUE: V_TEL_LOOKUP_ALL
-- Description: Toutes les tables de référence en une seule requête
-- Usage: Chargement initial des listes déroulantes dans l'interface
-- ============================================================================
IF EXISTS (SELECT * FROM sys.views WHERE name = 'V_TEL_LOOKUP_ALL')
    DROP VIEW [dbo].[V_TEL_LOOKUP_ALL];
GO

CREATE VIEW [dbo].[V_TEL_LOOKUP_ALL]
AS
SELECT 'INDICATIF' AS [table_name], [id], [code], [libelle], NULL AS [extra], [actif]
FROM [dbo].[TEL_INDICATIF]
UNION ALL
SELECT 'OPERATEUR', [id], [code], [nom], [type], [actif]
FROM [dbo].[TEL_OPERATEUR]
UNION ALL
SELECT 'TYPE_DID', [id], [code], [libelle], NULL, [actif]
FROM [dbo].[TEL_TYPE_DID]
UNION ALL
SELECT 'EQUIPEMENT', [id], [code], [nom], [type], [actif]
FROM [dbo].[TEL_EQUIPEMENT]
UNION ALL
SELECT 'STATUT_DID', [id], [code], [libelle], [couleur], [actif]
FROM [dbo].[TEL_STATUT_DID]
UNION ALL
SELECT 'STATUT_COMMANDE', [id], [code], [libelle], [couleur], [actif]
FROM [dbo].[TEL_STATUT_COMMANDE]
UNION ALL
SELECT 'CLOUD', [id], [code], [nom], [routage], [actif]
FROM [dbo].[TEL_CLOUD];
GO

PRINT 'Vue V_TEL_LOOKUP_ALL créée avec succès';
GO

PRINT '============================================';
PRINT 'Script 06_views.sql terminé';
PRINT '============================================';
GO
