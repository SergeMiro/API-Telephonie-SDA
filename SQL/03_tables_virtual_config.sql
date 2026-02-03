-- ============================================================================
-- SCRIPT: 03_tables_virtual_config.sql
-- BASE: FIMLONSQL2.HN_FIMAINFO_CONFIG
-- DESCRIPTION: Tables DID_VIRTUAL (affectation campagnes) et DID_CONFIG (JSON)
-- DATE: 03 février 2026
-- ============================================================================

USE HN_FIMAINFO_CONFIG;
GO

-- ============================================================================
-- TABLE: TEL_DID_CONFIG
-- Description: Configuration JSON pour personnalisation des DID
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_DID_CONFIG]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_DID_CONFIG] (
        [id]                INT IDENTITY(1,1) NOT NULL,
        [code]              VARCHAR(50) NOT NULL,
        [nom]               NVARCHAR(200) NOT NULL,
        [description]       NVARCHAR(500) NULL,

        -- Configuration JSON
        [config]            NVARCHAR(MAX) NULL,            -- JSON configuration
        /*
            Structure JSON attendue:
            {
                "nom_site": "Mon Site",
                "couleur": "#FF5500",
                "logo": "url_du_logo.png",
                "message_accueil": "Bienvenue...",
                "horaires": {
                    "lundi": {"debut": "09:00", "fin": "18:00"},
                    ...
                },
                "redirection_hors_horaires": "+33612345678",
                "options": {
                    "enregistrement": true,
                    "musique_attente": "default",
                    "annonce_position": true
                }
            }
        */

        -- Métadonnées
        [actif]             BIT NOT NULL DEFAULT 1,
        [created_by]        NVARCHAR(100) NULL,
        [modified_by]       NVARCHAR(100) NULL,
        [date_creation]     DATETIME NOT NULL DEFAULT GETDATE(),
        [date_modification] DATETIME NULL,

        CONSTRAINT [PK_TEL_DID_CONFIG] PRIMARY KEY CLUSTERED ([id]),
        CONSTRAINT [UQ_TEL_DID_CONFIG_code] UNIQUE ([code]),

        -- Validation JSON (SQL Server 2016+)
        CONSTRAINT [CK_TEL_DID_CONFIG_json] CHECK (
            [config] IS NULL OR ISJSON([config]) = 1
        )
    );
    PRINT 'Table TEL_DID_CONFIG créée avec succès';
END
GO

-- ============================================================================
-- TABLE: TEL_DID_VIRTUAL
-- Description: Affectation des DID aux campagnes Hermes
-- Un même DID peut être affecté à plusieurs campagnes (historique)
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_DID_VIRTUAL]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_DID_VIRTUAL] (
        [id]                INT IDENTITY(1,1) NOT NULL,

        -- Liaison DID → Campagne
        [did_id]            INT NOT NULL,                  -- FK → TEL_DID
        [campaign_id]       INT NOT NULL,                  -- FK → TEL_CAMPAIGN
        [config_id]         INT NULL,                      -- FK → TEL_DID_CONFIG

        -- Paramètres d'affectation
        [alias]             NVARCHAR(100) NULL,            -- Alias/nom d'affichage
        [priorite]          INT NOT NULL DEFAULT 1,        -- Priorité si plusieurs DID

        -- Période d'affectation
        [date_debut]        DATE NOT NULL DEFAULT GETDATE(),
        [date_fin]          DATE NULL,                     -- NULL = toujours actif

        -- Direction d'appels
        [entrant]           BIT NOT NULL DEFAULT 1,        -- Utilisable en entrant
        [sortant]           BIT NOT NULL DEFAULT 1,        -- Utilisable en sortant

        -- Métadonnées
        [actif]             BIT NOT NULL DEFAULT 1,
        [created_by]        NVARCHAR(100) NULL,
        [modified_by]       NVARCHAR(100) NULL,
        [date_creation]     DATETIME NOT NULL DEFAULT GETDATE(),
        [date_modification] DATETIME NULL,

        CONSTRAINT [PK_TEL_DID_VIRTUAL] PRIMARY KEY CLUSTERED ([id]),

        -- Clés étrangères
        CONSTRAINT [FK_TEL_DID_VIRTUAL_did] FOREIGN KEY ([did_id])
            REFERENCES [dbo].[TEL_DID]([id]),
        CONSTRAINT [FK_TEL_DID_VIRTUAL_campaign] FOREIGN KEY ([campaign_id])
            REFERENCES [dbo].[TEL_CAMPAIGN]([id]),
        CONSTRAINT [FK_TEL_DID_VIRTUAL_config] FOREIGN KEY ([config_id])
            REFERENCES [dbo].[TEL_DID_CONFIG]([id])
    );
    PRINT 'Table TEL_DID_VIRTUAL créée avec succès';
END
GO

-- ============================================================================
-- TABLE: TEL_DID_HISTORIQUE
-- Description: Historique des changements sur les DID (audit)
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_DID_HISTORIQUE]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_DID_HISTORIQUE] (
        [id]                BIGINT IDENTITY(1,1) NOT NULL,
        [did_id]            INT NOT NULL,
        [action]            VARCHAR(20) NOT NULL,          -- INSERT, UPDATE, DELETE
        [champ_modifie]     VARCHAR(100) NULL,
        [ancienne_valeur]   NVARCHAR(500) NULL,
        [nouvelle_valeur]   NVARCHAR(500) NULL,
        [utilisateur]       NVARCHAR(100) NULL,
        [date_action]       DATETIME NOT NULL DEFAULT GETDATE(),

        CONSTRAINT [PK_TEL_DID_HISTORIQUE] PRIMARY KEY CLUSTERED ([id])
    );
    PRINT 'Table TEL_DID_HISTORIQUE créée avec succès';
END
GO

-- ============================================================================
-- TRIGGER: Historique des modifications DID
-- ============================================================================
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'TR_TEL_DID_Historique')
    DROP TRIGGER [dbo].[TR_TEL_DID_Historique];
GO

CREATE TRIGGER [dbo].[TR_TEL_DID_Historique]
ON [dbo].[TEL_DID]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Historique changement de statut
    INSERT INTO [dbo].[TEL_DID_HISTORIQUE] ([did_id], [action], [champ_modifie], [ancienne_valeur], [nouvelle_valeur], [utilisateur])
    SELECT
        i.[id],
        'UPDATE',
        'statut_id',
        CAST(d.[statut_id] AS NVARCHAR(500)),
        CAST(i.[statut_id] AS NVARCHAR(500)),
        i.[modified_by]
    FROM inserted i
    INNER JOIN deleted d ON i.[id] = d.[id]
    WHERE i.[statut_id] <> d.[statut_id];

    -- Historique changement de client
    INSERT INTO [dbo].[TEL_DID_HISTORIQUE] ([did_id], [action], [champ_modifie], [ancienne_valeur], [nouvelle_valeur], [utilisateur])
    SELECT
        i.[id],
        'UPDATE',
        'client_id',
        CAST(d.[client_id] AS NVARCHAR(500)),
        CAST(i.[client_id] AS NVARCHAR(500)),
        i.[modified_by]
    FROM inserted i
    INNER JOIN deleted d ON i.[id] = d.[id]
    WHERE ISNULL(i.[client_id], 0) <> ISNULL(d.[client_id], 0);
END
GO

PRINT 'Trigger TR_TEL_DID_Historique créé avec succès';
GO

PRINT '============================================';
PRINT 'Script 03_tables_virtual_config.sql terminé';
PRINT '============================================';
GO
