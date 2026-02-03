-- ============================================================================
-- SCRIPT: 04_table_commande.sql
-- BASE: FIMLONSQL2.HN_FIMAINFO_CONFIG
-- DESCRIPTION: Tables pour la gestion des commandes de SDA
-- DATE: 03 février 2026
-- ============================================================================

USE HN_FIMAINFO_CONFIG;
GO

-- ============================================================================
-- TABLE: TEL_STATUT_COMMANDE
-- Description: Statuts possibles pour une demande de commande
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_STATUT_COMMANDE]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_STATUT_COMMANDE] (
        [id]            INT IDENTITY(1,1) NOT NULL,
        [code]          VARCHAR(20) NOT NULL,
        [libelle]       NVARCHAR(100) NOT NULL,
        [description]   NVARCHAR(500) NULL,
        [ordre]         INT NOT NULL DEFAULT 0,
        [couleur]       VARCHAR(7) NULL,
        [actif]         BIT NOT NULL DEFAULT 1,
        [date_creation] DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_TEL_STATUT_COMMANDE] PRIMARY KEY CLUSTERED ([id]),
        CONSTRAINT [UQ_TEL_STATUT_COMMANDE_code] UNIQUE ([code])
    );
    PRINT 'Table TEL_STATUT_COMMANDE créée avec succès';
END
GO

-- Données initiales STATUT_COMMANDE
IF NOT EXISTS (SELECT 1 FROM [dbo].[TEL_STATUT_COMMANDE])
BEGIN
    INSERT INTO [dbo].[TEL_STATUT_COMMANDE] ([code], [libelle], [description], [ordre], [couleur]) VALUES
    ('BROUILLON', 'Brouillon', 'Demande en cours de rédaction', 1, '#6C757D'),
    ('SOUMISE', 'Soumise', 'Demande soumise, en attente de validation', 2, '#17A2B8'),
    ('VALIDEE', 'Validée', 'Demande validée par le responsable', 3, '#007BFF'),
    ('EN_COURS', 'En cours', 'Commande transmise à l''opérateur', 4, '#FFC107'),
    ('LIVREE', 'Livrée', 'Numéros reçus et configurés', 5, '#28A745'),
    ('REJETEE', 'Rejetée', 'Demande rejetée', 6, '#DC3545'),
    ('ANNULEE', 'Annulée', 'Demande annulée par le demandeur', 7, '#6C757D');
    PRINT 'Données initiales TEL_STATUT_COMMANDE insérées';
END
GO

-- ============================================================================
-- TABLE: TEL_DID_COMMANDE
-- Description: Demandes de commande de numéros SDA
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_DID_COMMANDE]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_DID_COMMANDE] (
        [id]                    INT IDENTITY(1,1) NOT NULL,

        -- Référence unique de la commande
        [reference]             VARCHAR(20) NOT NULL,          -- Ex: CMD-2026-00001

        -- Demandeur
        [client_id]             INT NOT NULL,                  -- FK → TEL_CLIENT
        [groupement_id]         INT NULL,                      -- FK → TEL_GROUPEMENT
        [demandeur_nom]         NVARCHAR(100) NOT NULL,
        [demandeur_email]       NVARCHAR(255) NOT NULL,
        [demandeur_tel]         VARCHAR(20) NULL,

        -- Détails de la commande
        [operateur_id]          INT NULL,                      -- FK → TEL_OPERATEUR (si préférence)
        [type_did_id]           INT NOT NULL,                  -- FK → TEL_TYPE_DID
        [region_id]             INT NULL,                      -- FK → TEL_REGION (pour géographique)
        [quantite]              INT NOT NULL DEFAULT 1,
        [prefixe_souhaite]      VARCHAR(10) NULL,              -- Ex: 01, 04, 06...
        [motif]                 NVARCHAR(500) NULL,            -- Motif de la demande

        -- Urgence et priorité
        [urgence]               VARCHAR(10) NOT NULL DEFAULT 'NORMALE',  -- BASSE, NORMALE, HAUTE, URGENTE
        [date_souhaitee]        DATE NULL,                     -- Date de livraison souhaitée

        -- Statut
        [statut_id]             INT NOT NULL,                  -- FK → TEL_STATUT_COMMANDE

        -- Traitement
        [valideur_nom]          NVARCHAR(100) NULL,
        [date_validation]       DATETIME NULL,
        [commentaire_validation] NVARCHAR(500) NULL,
        [reference_operateur]   VARCHAR(100) NULL,             -- Référence commande opérateur
        [date_livraison]        DATE NULL,

        -- Métadonnées
        [actif]                 BIT NOT NULL DEFAULT 1,
        [created_by]            NVARCHAR(100) NULL,
        [modified_by]           NVARCHAR(100) NULL,
        [date_creation]         DATETIME NOT NULL DEFAULT GETDATE(),
        [date_modification]     DATETIME NULL,

        CONSTRAINT [PK_TEL_DID_COMMANDE] PRIMARY KEY CLUSTERED ([id]),
        CONSTRAINT [UQ_TEL_DID_COMMANDE_reference] UNIQUE ([reference]),

        -- Clés étrangères
        CONSTRAINT [FK_TEL_DID_COMMANDE_client] FOREIGN KEY ([client_id])
            REFERENCES [dbo].[TEL_CLIENT]([id]),
        CONSTRAINT [FK_TEL_DID_COMMANDE_groupement] FOREIGN KEY ([groupement_id])
            REFERENCES [dbo].[TEL_GROUPEMENT]([id]),
        CONSTRAINT [FK_TEL_DID_COMMANDE_operateur] FOREIGN KEY ([operateur_id])
            REFERENCES [dbo].[TEL_OPERATEUR]([id]),
        CONSTRAINT [FK_TEL_DID_COMMANDE_type] FOREIGN KEY ([type_did_id])
            REFERENCES [dbo].[TEL_TYPE_DID]([id]),
        CONSTRAINT [FK_TEL_DID_COMMANDE_region] FOREIGN KEY ([region_id])
            REFERENCES [dbo].[TEL_REGION]([id]),
        CONSTRAINT [FK_TEL_DID_COMMANDE_statut] FOREIGN KEY ([statut_id])
            REFERENCES [dbo].[TEL_STATUT_COMMANDE]([id]),

        -- Contraintes de validation
        CONSTRAINT [CK_TEL_DID_COMMANDE_quantite] CHECK ([quantite] > 0 AND [quantite] <= 1000),
        CONSTRAINT [CK_TEL_DID_COMMANDE_urgence] CHECK ([urgence] IN ('BASSE', 'NORMALE', 'HAUTE', 'URGENTE'))
    );
    PRINT 'Table TEL_DID_COMMANDE créée avec succès';
END
GO

-- ============================================================================
-- TABLE: TEL_DID_COMMANDE_LIGNE
-- Description: Numéros livrés pour une commande (après livraison)
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_DID_COMMANDE_LIGNE]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_DID_COMMANDE_LIGNE] (
        [id]                INT IDENTITY(1,1) NOT NULL,
        [commande_id]       INT NOT NULL,                  -- FK → TEL_DID_COMMANDE
        [did_id]            INT NOT NULL,                  -- FK → TEL_DID (numéro livré)
        [date_creation]     DATETIME NOT NULL DEFAULT GETDATE(),

        CONSTRAINT [PK_TEL_DID_COMMANDE_LIGNE] PRIMARY KEY CLUSTERED ([id]),
        CONSTRAINT [FK_TEL_DID_COMMANDE_LIGNE_commande] FOREIGN KEY ([commande_id])
            REFERENCES [dbo].[TEL_DID_COMMANDE]([id]),
        CONSTRAINT [FK_TEL_DID_COMMANDE_LIGNE_did] FOREIGN KEY ([did_id])
            REFERENCES [dbo].[TEL_DID]([id]),
        CONSTRAINT [UQ_TEL_DID_COMMANDE_LIGNE] UNIQUE ([commande_id], [did_id])
    );
    PRINT 'Table TEL_DID_COMMANDE_LIGNE créée avec succès';
END
GO

-- ============================================================================
-- TABLE: TEL_DID_COMMANDE_COMMENTAIRE
-- Description: Historique des commentaires sur une commande
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_DID_COMMANDE_COMMENTAIRE]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_DID_COMMANDE_COMMENTAIRE] (
        [id]                INT IDENTITY(1,1) NOT NULL,
        [commande_id]       INT NOT NULL,
        [auteur]            NVARCHAR(100) NOT NULL,
        [commentaire]       NVARCHAR(MAX) NOT NULL,
        [type]              VARCHAR(20) NOT NULL DEFAULT 'INFO',  -- INFO, VALIDATION, REJET, LIVRAISON
        [date_creation]     DATETIME NOT NULL DEFAULT GETDATE(),

        CONSTRAINT [PK_TEL_DID_COMMANDE_COMMENTAIRE] PRIMARY KEY CLUSTERED ([id]),
        CONSTRAINT [FK_TEL_DID_COMMANDE_COMMENTAIRE_commande] FOREIGN KEY ([commande_id])
            REFERENCES [dbo].[TEL_DID_COMMANDE]([id])
    );
    PRINT 'Table TEL_DID_COMMANDE_COMMENTAIRE créée avec succès';
END
GO

-- ============================================================================
-- SEQUENCE: Génération des références de commande
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.sequences WHERE name = 'SEQ_COMMANDE_REF')
BEGIN
    CREATE SEQUENCE [dbo].[SEQ_COMMANDE_REF]
        AS INT
        START WITH 1
        INCREMENT BY 1
        MINVALUE 1
        MAXVALUE 99999
        CYCLE;
    PRINT 'Séquence SEQ_COMMANDE_REF créée avec succès';
END
GO

-- ============================================================================
-- TRIGGER: Génération automatique de la référence commande
-- Note: NEXT VALUE FOR ne peut pas être utilisé dans une fonction scalaire,
--       donc la logique est directement dans le trigger
-- ============================================================================
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'TR_TEL_DID_COMMANDE_Reference')
    DROP TRIGGER [dbo].[TR_TEL_DID_COMMANDE_Reference];
GO

CREATE TRIGGER [dbo].[TR_TEL_DID_COMMANDE_Reference]
ON [dbo].[TEL_DID_COMMANDE]
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Génération de la référence directement dans le trigger
    DECLARE @year VARCHAR(4) = CAST(YEAR(GETDATE()) AS VARCHAR(4));

    INSERT INTO [dbo].[TEL_DID_COMMANDE] (
        [reference], [client_id], [groupement_id], [demandeur_nom], [demandeur_email],
        [demandeur_tel], [operateur_id], [type_did_id], [region_id], [quantite],
        [prefixe_souhaite], [motif], [urgence], [date_souhaitee], [statut_id],
        [valideur_nom], [date_validation], [commentaire_validation], [reference_operateur],
        [date_livraison], [actif], [created_by], [modified_by], [date_creation], [date_modification]
    )
    SELECT
        'CMD-' + @year + '-' + RIGHT('00000' + CAST(NEXT VALUE FOR [dbo].[SEQ_COMMANDE_REF] AS VARCHAR(5)), 5),
        [client_id], [groupement_id], [demandeur_nom], [demandeur_email],
        [demandeur_tel], [operateur_id], [type_did_id], [region_id], [quantite],
        [prefixe_souhaite], [motif], [urgence], [date_souhaitee],
        ISNULL([statut_id], (SELECT [id] FROM [dbo].[TEL_STATUT_COMMANDE] WHERE [code] = 'BROUILLON')),
        [valideur_nom], [date_validation], [commentaire_validation], [reference_operateur],
        [date_livraison], ISNULL([actif], 1), [created_by], [modified_by],
        ISNULL([date_creation], GETDATE()), [date_modification]
    FROM inserted;
END
GO

PRINT 'Trigger TR_TEL_DID_COMMANDE_Reference créé avec succès';
GO

-- ============================================================================
-- TRIGGER: Historique des changements de statut commande
-- ============================================================================
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'TR_TEL_DID_COMMANDE_Statut')
    DROP TRIGGER [dbo].[TR_TEL_DID_COMMANDE_Statut];
GO

CREATE TRIGGER [dbo].[TR_TEL_DID_COMMANDE_Statut]
ON [dbo].[TEL_DID_COMMANDE]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Si le statut a changé, ajouter un commentaire automatique
    INSERT INTO [dbo].[TEL_DID_COMMANDE_COMMENTAIRE] ([commande_id], [auteur], [commentaire], [type])
    SELECT
        i.[id],
        ISNULL(i.[modified_by], SYSTEM_USER),
        'Statut modifié: ' + ds.[libelle] + ' → ' + ns.[libelle],
        CASE ns.[code]
            WHEN 'VALIDEE' THEN 'VALIDATION'
            WHEN 'REJETEE' THEN 'REJET'
            WHEN 'LIVREE' THEN 'LIVRAISON'
            ELSE 'INFO'
        END
    FROM inserted i
    INNER JOIN deleted d ON i.[id] = d.[id]
    INNER JOIN [dbo].[TEL_STATUT_COMMANDE] ds ON d.[statut_id] = ds.[id]
    INNER JOIN [dbo].[TEL_STATUT_COMMANDE] ns ON i.[statut_id] = ns.[id]
    WHERE i.[statut_id] <> d.[statut_id];

    -- Mise à jour de la date de modification
    UPDATE c
    SET c.[date_modification] = GETDATE()
    FROM [dbo].[TEL_DID_COMMANDE] c
    INNER JOIN inserted i ON c.[id] = i.[id];
END
GO

PRINT 'Trigger TR_TEL_DID_COMMANDE_Statut créé avec succès';
GO

PRINT '============================================';
PRINT 'Script 04_table_commande.sql terminé';
PRINT '============================================';
GO
