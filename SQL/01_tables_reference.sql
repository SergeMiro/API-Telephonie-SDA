-- ============================================================================
-- SCRIPT: 01_tables_reference.sql
-- BASE: FIMLONSQL2.HN_FIMAINFO_CONFIG
-- DESCRIPTION: Création des tables de référence pour la gestion des DID
-- DATE: 03 février 2026
-- ============================================================================

USE HN_FIMAINFO_CONFIG;
GO

-- ============================================================================
-- TABLE: TEL_INDICATIF
-- Description: Indicatifs téléphoniques par pays
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_INDICATIF]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_INDICATIF] (
        [id]            INT IDENTITY(1,1) NOT NULL,
        [code]          VARCHAR(5) NOT NULL,           -- FR, BE, CH, EN...
        [indicatif]     VARCHAR(5) NOT NULL,           -- +33, +32, +41...
        [libelle]       NVARCHAR(100) NOT NULL,        -- France, Belgique...
        [actif]         BIT NOT NULL DEFAULT 1,
        [date_creation] DATETIME NOT NULL DEFAULT GETDATE(),
        [date_modification] DATETIME NULL,
        CONSTRAINT [PK_TEL_INDICATIF] PRIMARY KEY CLUSTERED ([id]),
        CONSTRAINT [UQ_TEL_INDICATIF_code] UNIQUE ([code])
    );
    PRINT 'Table TEL_INDICATIF créée avec succès';
END
GO

-- Données initiales INDICATIF
IF NOT EXISTS (SELECT 1 FROM [dbo].[TEL_INDICATIF])
BEGIN
    INSERT INTO [dbo].[TEL_INDICATIF] ([code], [indicatif], [libelle]) VALUES
    -- France métropolitaine
    ('FR', '+33', 'France'),
    -- DOM-TOM (Départements et Régions d''Outre-Mer)
    ('GP', '+590', 'Guadeloupe'),
    ('MQ', '+596', 'Martinique'),
    ('GF', '+594', 'Guyane française'),
    ('RE', '+262', 'La Réunion'),
    ('YT', '+262', 'Mayotte'),
    -- COM (Collectivités d''Outre-Mer)
    ('PM', '+508', 'Saint-Pierre-et-Miquelon'),
    ('MF', '+590', 'Saint-Martin'),
    ('BL', '+590', 'Saint-Barthélemy'),
    ('NC', '+687', 'Nouvelle-Calédonie'),
    ('PF', '+689', 'Polynésie française'),
    ('WF', '+681', 'Wallis-et-Futuna'),
    -- Europe
    ('BE', '+32', 'Belgique'),
    ('CH', '+41', 'Suisse'),
    ('LU', '+352', 'Luxembourg'),
    ('DE', '+49', 'Allemagne'),
    ('ES', '+34', 'Espagne'),
    ('IT', '+39', 'Italie'),
    ('GB', '+44', 'Royaume-Uni'),
    ('NL', '+31', 'Pays-Bas'),
    ('PT', '+351', 'Portugal');
    PRINT 'Données initiales TEL_INDICATIF insérées';
END
GO

-- ============================================================================
-- TABLE: TEL_REGION
-- Description: Régions géographiques pour les SDA (numéros régionaux)
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_REGION]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_REGION] (
        [id]            INT IDENTITY(1,1) NOT NULL,
        [indicatif_id]  INT NOT NULL,                  -- FK vers TEL_INDICATIF
        [code]          VARCHAR(10) NOT NULL,          -- IDF, PACA, NOR...
        [libelle]       NVARCHAR(100) NOT NULL,        -- Île-de-France, PACA...
        [prefixe]       VARCHAR(5) NULL,               -- 01, 04, 03... (pour France)
        [actif]         BIT NOT NULL DEFAULT 1,
        [date_creation] DATETIME NOT NULL DEFAULT GETDATE(),
        [date_modification] DATETIME NULL,
        CONSTRAINT [PK_TEL_REGION] PRIMARY KEY CLUSTERED ([id]),
        CONSTRAINT [FK_TEL_REGION_indicatif] FOREIGN KEY ([indicatif_id])
            REFERENCES [dbo].[TEL_INDICATIF]([id]),
        CONSTRAINT [UQ_TEL_REGION_code_indicatif] UNIQUE ([indicatif_id], [code])
    );
    PRINT 'Table TEL_REGION créée avec succès';
END
GO

-- Données initiales REGION (France)
IF NOT EXISTS (SELECT 1 FROM [dbo].[TEL_REGION])
BEGIN
    DECLARE @FR_ID INT = (SELECT [id] FROM [dbo].[TEL_INDICATIF] WHERE [code] = 'FR');

    INSERT INTO [dbo].[TEL_REGION] ([indicatif_id], [code], [libelle], [prefixe]) VALUES
    (@FR_ID, 'IDF', 'Île-de-France', '01'),
    (@FR_ID, 'NOR', 'Nord-Ouest', '02'),
    (@FR_ID, 'NES', 'Nord-Est', '03'),
    (@FR_ID, 'SES', 'Sud-Est', '04'),
    (@FR_ID, 'SOU', 'Sud-Ouest', '05'),
    (@FR_ID, 'MOB', 'Mobile', '06'),
    (@FR_ID, 'MOB2', 'Mobile (07)', '07'),
    (@FR_ID, 'NPV', 'Numéros non-géographiques', '09');
    PRINT 'Données initiales TEL_REGION insérées';
END
GO

-- ============================================================================
-- TABLE: TEL_OPERATEUR
-- Description: Opérateurs télécom fournisseurs de SDA
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_OPERATEUR]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_OPERATEUR] (
        [id]            INT IDENTITY(1,1) NOT NULL,
        [code]          VARCHAR(20) NOT NULL,          -- BOUYGUES, TELNYX...
        [nom]           NVARCHAR(100) NOT NULL,
        [type]          VARCHAR(20) NULL,              -- VOIP, TRADITIONNEL, HYBRIDE
        [contact]       NVARCHAR(255) NULL,
        [actif]         BIT NOT NULL DEFAULT 1,
        [date_creation] DATETIME NOT NULL DEFAULT GETDATE(),
        [date_modification] DATETIME NULL,
        CONSTRAINT [PK_TEL_OPERATEUR] PRIMARY KEY CLUSTERED ([id]),
        CONSTRAINT [UQ_TEL_OPERATEUR_code] UNIQUE ([code])
    );
    PRINT 'Table TEL_OPERATEUR créée avec succès';
END
GO

-- Données initiales OPERATEUR
IF NOT EXISTS (SELECT 1 FROM [dbo].[TEL_OPERATEUR])
BEGIN
    INSERT INTO [dbo].[TEL_OPERATEUR] ([code], [nom], [type]) VALUES
    ('BOUYGUES', 'Bouygues Telecom', 'TRADITIONNEL'),
    ('ORANGE', 'Orange Business', 'TRADITIONNEL'),
    ('SFR', 'SFR Business', 'TRADITIONNEL'),
    ('TELNYX', 'Telnyx', 'VOIP'),
    ('TWILIO', 'Twilio', 'VOIP'),
    ('OVH', 'OVH Telecom', 'VOIP'),
    ('KEYYO', 'Keyyo', 'VOIP'),
    ('AIRCALL', 'Aircall', 'VOIP');
    PRINT 'Données initiales TEL_OPERATEUR insérées';
END
GO

-- ============================================================================
-- TABLE: TEL_TYPE_DID
-- Description: Types de numéros DID
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_TYPE_DID]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_TYPE_DID] (
        [id]            INT IDENTITY(1,1) NOT NULL,
        [code]          VARCHAR(20) NOT NULL,
        [libelle]       NVARCHAR(100) NOT NULL,
        [description]   NVARCHAR(500) NULL,
        [actif]         BIT NOT NULL DEFAULT 1,
        [date_creation] DATETIME NOT NULL DEFAULT GETDATE(),
        [date_modification] DATETIME NULL,
        CONSTRAINT [PK_TEL_TYPE_DID] PRIMARY KEY CLUSTERED ([id]),
        CONSTRAINT [UQ_TEL_TYPE_DID_code] UNIQUE ([code])
    );
    PRINT 'Table TEL_TYPE_DID créée avec succès';
END
GO

-- Données initiales TYPE_DID
IF NOT EXISTS (SELECT 1 FROM [dbo].[TEL_TYPE_DID])
BEGIN
    INSERT INTO [dbo].[TEL_TYPE_DID] ([code], [libelle], [description]) VALUES
    ('NPV', 'Numéro Non-géographique', 'Numéro en 09xx, non rattaché à une zone'),
    ('GEO', 'Géographique', 'Numéro rattaché à une zone géographique (01-05)'),
    ('MOBILE', 'Mobile', 'Numéro mobile (06, 07)'),
    ('SURTAXE', 'Numéro surtaxé', 'Numéro à tarification spéciale (08)'),
    ('VERT', 'Numéro vert', 'Numéro gratuit pour l''appelant'),
    ('INTERNATIONAL', 'International', 'Numéro hors France');
    PRINT 'Données initiales TEL_TYPE_DID insérées';
END
GO

-- ============================================================================
-- TABLE: TEL_EQUIPEMENT
-- Description: Équipements de routage téléphonique
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_EQUIPEMENT]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_EQUIPEMENT] (
        [id]            INT IDENTITY(1,1) NOT NULL,
        [code]          VARCHAR(20) NOT NULL,
        [nom]           NVARCHAR(100) NOT NULL,
        [type]          VARCHAR(50) NULL,              -- SBC, PBX, GATEWAY...
        [ip_address]    VARCHAR(45) NULL,
        [actif]         BIT NOT NULL DEFAULT 1,
        [date_creation] DATETIME NOT NULL DEFAULT GETDATE(),
        [date_modification] DATETIME NULL,
        CONSTRAINT [PK_TEL_EQUIPEMENT] PRIMARY KEY CLUSTERED ([id]),
        CONSTRAINT [UQ_TEL_EQUIPEMENT_code] UNIQUE ([code])
    );
    PRINT 'Table TEL_EQUIPEMENT créée avec succès';
END
GO

-- Données initiales EQUIPEMENT
IF NOT EXISTS (SELECT 1 FROM [dbo].[TEL_EQUIPEMENT])
BEGIN
    INSERT INTO [dbo].[TEL_EQUIPEMENT] ([code], [nom], [type]) VALUES
    ('SBC', 'Session Border Controller', 'SBC'),
    ('CENTREX', 'Centrex Bouygues', 'PBX'),
    ('T2', 'Trunk T2', 'TRUNK'),
    ('ASTRA', 'Astra PBX', 'PBX'),
    ('ASTERISK', 'Asterisk Server', 'PBX'),
    ('FREESWITCH', 'FreeSWITCH', 'SOFTSWITCH');
    PRINT 'Données initiales TEL_EQUIPEMENT insérées';
END
GO

-- ============================================================================
-- TABLE: TEL_STATUT_DID
-- Description: Statuts possibles pour un DID
-- Ajout des statuts: Commandé, Disponible (en plus de Résilié, Affecté, Utilisé)
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_STATUT_DID]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_STATUT_DID] (
        [id]            INT IDENTITY(1,1) NOT NULL,
        [code]          VARCHAR(20) NOT NULL,
        [libelle]       NVARCHAR(100) NOT NULL,
        [description]   NVARCHAR(500) NULL,
        [ordre]         INT NOT NULL DEFAULT 0,        -- Pour l'ordre d'affichage
        [couleur]       VARCHAR(7) NULL,               -- Code couleur hex (#FF0000)
        [actif]         BIT NOT NULL DEFAULT 1,
        [date_creation] DATETIME NOT NULL DEFAULT GETDATE(),
        [date_modification] DATETIME NULL,
        CONSTRAINT [PK_TEL_STATUT_DID] PRIMARY KEY CLUSTERED ([id]),
        CONSTRAINT [UQ_TEL_STATUT_DID_code] UNIQUE ([code])
    );
    PRINT 'Table TEL_STATUT_DID créée avec succès';
END
GO

-- Données initiales STATUT_DID (avec nouveaux statuts)
IF NOT EXISTS (SELECT 1 FROM [dbo].[TEL_STATUT_DID])
BEGIN
    INSERT INTO [dbo].[TEL_STATUT_DID] ([code], [libelle], [description], [ordre], [couleur]) VALUES
    ('COMMANDE', 'Commandé', 'Numéro en cours de commande auprès de l''opérateur', 1, '#FFA500'),
    ('DISPONIBLE', 'Disponible', 'Numéro disponible sur le client, non affecté à une campagne', 2, '#17A2B8'),
    ('AFFECTE', 'Affecté', 'Numéro attribué à un client mais non utilisé actuellement', 3, '#FFC107'),
    ('UTILISE', 'Utilisé', 'Numéro en production active', 4, '#28A745'),
    ('RESILIE', 'Résilié', 'Numéro non actif, libéré ou en cours de résiliation', 5, '#DC3545');
    PRINT 'Données initiales TEL_STATUT_DID insérées';
END
GO

-- ============================================================================
-- TABLE: TEL_CLOUD
-- Description: Environnements cloud/infrastructure
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_CLOUD]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_CLOUD] (
        [id]            INT IDENTITY(1,1) NOT NULL,
        [code]          VARCHAR(20) NOT NULL,
        [nom]           NVARCHAR(100) NOT NULL,
        [routage]       NVARCHAR(255) NULL,            -- Configuration de routage
        [actif]         BIT NOT NULL DEFAULT 1,
        [date_creation] DATETIME NOT NULL DEFAULT GETDATE(),
        [date_modification] DATETIME NULL,
        CONSTRAINT [PK_TEL_CLOUD] PRIMARY KEY CLUSTERED ([id]),
        CONSTRAINT [UQ_TEL_CLOUD_code] UNIQUE ([code])
    );
    PRINT 'Table TEL_CLOUD créée avec succès';
END
GO

-- ============================================================================
-- TABLE: TEL_CLIENT
-- Description: Clients Fimainfo
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_CLIENT]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_CLIENT] (
        [id]            INT IDENTITY(1,1) NOT NULL,
        [code]          VARCHAR(20) NOT NULL,
        [nom]           NVARCHAR(200) NOT NULL,
        [siret]         VARCHAR(14) NULL,
        [adresse]       NVARCHAR(500) NULL,
        [contact_nom]   NVARCHAR(100) NULL,
        [contact_email] NVARCHAR(255) NULL,
        [contact_tel]   VARCHAR(20) NULL,
        [actif]         BIT NOT NULL DEFAULT 1,
        [date_creation] DATETIME NOT NULL DEFAULT GETDATE(),
        [date_modification] DATETIME NULL,
        CONSTRAINT [PK_TEL_CLIENT] PRIMARY KEY CLUSTERED ([id]),
        CONSTRAINT [UQ_TEL_CLIENT_code] UNIQUE ([code])
    );
    PRINT 'Table TEL_CLIENT créée avec succès';
END
GO

-- ============================================================================
-- TABLE: TEL_GROUPEMENT
-- Description: Sous-entités / groupements par client
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_GROUPEMENT]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_GROUPEMENT] (
        [id]            INT IDENTITY(1,1) NOT NULL,
        [client_id]     INT NOT NULL,
        [code]          VARCHAR(50) NOT NULL,
        [libelle]       NVARCHAR(200) NOT NULL,
        [description]   NVARCHAR(500) NULL,
        [actif]         BIT NOT NULL DEFAULT 1,
        [date_creation] DATETIME NOT NULL DEFAULT GETDATE(),
        [date_modification] DATETIME NULL,
        CONSTRAINT [PK_TEL_GROUPEMENT] PRIMARY KEY CLUSTERED ([id]),
        CONSTRAINT [FK_TEL_GROUPEMENT_client] FOREIGN KEY ([client_id])
            REFERENCES [dbo].[TEL_CLIENT]([id]),
        CONSTRAINT [UQ_TEL_GROUPEMENT_client_code] UNIQUE ([client_id], [code])
    );
    PRINT 'Table TEL_GROUPEMENT créée avec succès';
END
GO

-- ============================================================================
-- TABLE: TEL_CAMPAIGN
-- Description: Campagnes Hermes
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEL_CAMPAIGN]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TEL_CAMPAIGN] (
        [id]            INT IDENTITY(1,1) NOT NULL,
        [client_id]     INT NOT NULL,
        [code]          VARCHAR(50) NOT NULL,
        [nom]           NVARCHAR(200) NOT NULL,
        [description]   NVARCHAR(500) NULL,
        [hermes_id]     VARCHAR(50) NULL,              -- ID dans Hermes si existant
        [actif]         BIT NOT NULL DEFAULT 1,
        [date_creation] DATETIME NOT NULL DEFAULT GETDATE(),
        [date_modification] DATETIME NULL,
        CONSTRAINT [PK_TEL_CAMPAIGN] PRIMARY KEY CLUSTERED ([id]),
        CONSTRAINT [FK_TEL_CAMPAIGN_client] FOREIGN KEY ([client_id])
            REFERENCES [dbo].[TEL_CLIENT]([id])
    );
    PRINT 'Table TEL_CAMPAIGN créée avec succès';
END
GO

PRINT '============================================';
PRINT 'Script 01_tables_reference.sql terminé';
PRINT '============================================';
GO
