-- ============================================================================
-- SCRIPT: 02_table_did.sql
-- BASE: FIMLONSQL2.HN_FIMAINFO_CONFIG
-- DESCRIPTION: Création de la table principale DID (inventaire des numéros)
-- DATE: 03 février 2026
-- ============================================================================

USE HN_FIMAINFO_CONFIG;
GO

-- ============================================================================
-- TABLE: TEL_DID
-- Description: Table principale d'inventaire de tous les numéros DID
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_DID]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_DID] (
        -- Identifiant
        [id]                INT IDENTITY(1,1) NOT NULL,

        -- Numéro de téléphone
        [indicatif_id]      INT NOT NULL,                  -- FK → TEL_INDICATIF
        [did]               VARCHAR(20) NOT NULL,          -- Numéro (9 chiffres pour FR)
        [did_format_e164]   VARCHAR(20) NULL,              -- Format E.164 (+33612345678)

        -- Classification
        [operateur_id]      INT NOT NULL,                  -- FK → TEL_OPERATEUR
        [type_id]           INT NOT NULL,                  -- FK → TEL_TYPE_DID
        [region_id]         INT NULL,                      -- FK → TEL_REGION (nouveau)
        [equipement_id]     INT NULL,                      -- FK → TEL_EQUIPEMENT

        -- Affectation
        [client_id]         INT NULL,                      -- FK → TEL_CLIENT
        [groupement_id]     INT NULL,                      -- FK → TEL_GROUPEMENT
        [cloud_id]          INT NULL,                      -- FK → TEL_CLOUD

        -- Statut
        [statut_id]         INT NOT NULL,                  -- FK → TEL_STATUT_DID

        -- Informations complémentaires
        [description]       NVARCHAR(500) NULL,            -- Description libre
        [reference_externe] VARCHAR(100) NULL,             -- Référence chez l'opérateur
        [date_acquisition]  DATE NULL,                     -- Date d'acquisition du numéro
        [date_activation]   DATE NULL,                     -- Date de mise en service
        [date_resiliation]  DATE NULL,                     -- Date de résiliation
        [cout_mensuel]      DECIMAL(10,2) NULL,            -- Coût mensuel
        [notes]             NVARCHAR(MAX) NULL,            -- Notes diverses

        -- Métadonnées
        [actif]             BIT NOT NULL DEFAULT 1,
        [created_by]        NVARCHAR(100) NULL,
        [modified_by]       NVARCHAR(100) NULL,
        [date_creation]     DATETIME NOT NULL DEFAULT GETDATE(),
        [date_modification] DATETIME NULL,

        -- Contraintes
        CONSTRAINT [PK_TEL_DID] PRIMARY KEY CLUSTERED ([id]),

        -- Unicité du numéro par indicatif
        CONSTRAINT [UQ_TEL_DID_indicatif_did] UNIQUE ([indicatif_id], [did]),

        -- Clés étrangères
        CONSTRAINT [FK_TEL_DID_indicatif] FOREIGN KEY ([indicatif_id])
            REFERENCES [dbo].[TEL_INDICATIF]([id]),
        CONSTRAINT [FK_TEL_DID_operateur] FOREIGN KEY ([operateur_id])
            REFERENCES [dbo].[TEL_OPERATEUR]([id]),
        CONSTRAINT [FK_TEL_DID_type] FOREIGN KEY ([type_id])
            REFERENCES [dbo].[TEL_TYPE_DID]([id]),
        CONSTRAINT [FK_TEL_DID_region] FOREIGN KEY ([region_id])
            REFERENCES [dbo].[TEL_REGION]([id]),
        CONSTRAINT [FK_TEL_DID_equipement] FOREIGN KEY ([equipement_id])
            REFERENCES [dbo].[TEL_EQUIPEMENT]([id]),
        CONSTRAINT [FK_TEL_DID_client] FOREIGN KEY ([client_id])
            REFERENCES [dbo].[TEL_CLIENT]([id]),
        CONSTRAINT [FK_TEL_DID_groupement] FOREIGN KEY ([groupement_id])
            REFERENCES [dbo].[TEL_GROUPEMENT]([id]),
        CONSTRAINT [FK_TEL_DID_cloud] FOREIGN KEY ([cloud_id])
            REFERENCES [dbo].[TEL_CLOUD]([id]),
        CONSTRAINT [FK_TEL_DID_statut] FOREIGN KEY ([statut_id])
            REFERENCES [dbo].[TEL_STATUT_DID]([id])
    );
    PRINT 'Table TEL_DID créée avec succès';
END
GO

-- ============================================================================
-- TRIGGER: Génération automatique du format E.164
-- ============================================================================
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'TR_TEL_DID_Format_E164')
    DROP TRIGGER [dbo].[TR_TEL_DID_Format_E164];
GO

CREATE TRIGGER [dbo].[TR_TEL_DID_Format_E164]
ON [dbo].[TEL_DID]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE d
    SET d.[did_format_e164] = i.[indicatif] +
        CASE
            WHEN LEFT(ins.[did], 1) = '0' THEN SUBSTRING(ins.[did], 2, LEN(ins.[did]) - 1)
            ELSE ins.[did]
        END,
        d.[date_modification] = CASE WHEN EXISTS (SELECT 1 FROM deleted) THEN GETDATE() ELSE d.[date_modification] END
    FROM [dbo].[TEL_DID] d
    INNER JOIN inserted ins ON d.[id] = ins.[id]
    INNER JOIN [dbo].[TEL_INDICATIF] i ON ins.[indicatif_id] = i.[id];
END
GO

PRINT 'Trigger TR_TEL_DID_Format_E164 créé avec succès';
GO

-- ============================================================================
-- TRIGGER: Mise à jour automatique de date_modification
-- ============================================================================
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'TR_TEL_DID_Update_Date')
    DROP TRIGGER [dbo].[TR_TEL_DID_Update_Date];
GO

CREATE TRIGGER [dbo].[TR_TEL_DID_Update_Date]
ON [dbo].[TEL_DID]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE([date_modification])
    BEGIN
        UPDATE d
        SET d.[date_modification] = GETDATE()
        FROM [dbo].[TEL_DID] d
        INNER JOIN inserted i ON d.[id] = i.[id];
    END
END
GO

PRINT 'Trigger TR_TEL_DID_Update_Date créé avec succès';
GO

PRINT '============================================';
PRINT 'Script 02_table_did.sql terminé';
PRINT '============================================';
GO


-- VOIR lES TRIGGER  - dans la doc 