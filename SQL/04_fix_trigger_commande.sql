-- ============================================================================
-- SCRIPT: 04_fix_trigger_commande.sql
-- DESCRIPTION: Correction du trigger de génération de référence commande
-- DATE: 03 février 2026
-- ============================================================================
-- Ce script corrige l'erreur: "NEXT VALUE FOR n'est pas autorisée dans les
-- fonctions définies par l'utilisateur"
-- ============================================================================

USE HN_FIMAINFO_CONFIG;
GO

-- Supprimer la fonction défaillante si elle existe
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GenerateCommandeRef]') AND type = 'FN')
BEGIN
    DROP FUNCTION [dbo].[fn_GenerateCommandeRef];
    PRINT 'Fonction fn_GenerateCommandeRef supprimée';
END
GO

-- Recréer le trigger avec la logique intégrée
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

PRINT 'Trigger TR_TEL_DID_COMMANDE_Reference recréé avec succès';
GO

-- Test du trigger
PRINT '';
PRINT 'Test de génération de référence:';
PRINT 'Référence attendue: CMD-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) + '-XXXXX';
GO
