
-- ANALYSE PRODUITS 
--- 2. GESTION DES STOCKS
------- 1. Nombre de semaines d'autonomie avec le stock de 8500 unités 
------- 2. Immobilisation du capital

------------------------------------------------------------
------- 1.Nombre de semaines d'autonomie avec du stock 
------------------------------------------------------------

-- On utilise un point de référence analytique de 8500 unités en stock maximum à répartir entre les catégories.

WITH volume_vendu AS (
-- Calcul des ventes journalières dans chaque catégorie :
		SELECT
		    categorie,
			reference_produit,
		    fact_ventes.produit_id,
			SUM(quantite_vendue) AS volume_total_vendu_3ans,
			ROUND(((SUM(quantite_vendue) * 100.0)/SUM(SUM(quantite_vendue)) OVER ())::NUMERIC, 2) AS pct_volume_total
				  
		FROM fact_ventes
		LEFT JOIN dim_produits
		    ON dim_produits.produit_id = fact_ventes.produit_id
		GROUP BY categorie, reference_produit, fact_ventes.produit_id
),

delai_transaction AS (
-- Affiche la date de la derniere et de l'avant-derniere transaction pour chaque produit :
	SELECT
        produit_id,
        date_transaction,
        LAG(date_transaction, 1) OVER (
          PARTITION BY produit_id
		  ORDER BY date_transaction ASC
        ) AS date_precedente
    FROM fact_ventes
),

stock_alloue AS (
-- Calcul des stocks necessaires et du volume vendu par semaine pour chaque reference :
	SELECT 
		reference_produit,
		produit_id,
		categorie,
		ROUND((volume_total_vendu_3ans::NUMERIC),2) AS volume_vendu_total,
		ROUND((volume_total_vendu_3ans::NUMERIC/3),2) AS volume_vendu_annee,
		ROUND((volume_total_vendu_3ans::NUMERIC/36),2) AS volume_vendu_mois,
		ROUND((volume_total_vendu_3ans::NUMERIC)/156.42,2) AS volume_vendu_semaine,
		ROUND(SUM(pct_volume_total) OVER (PARTITION BY categorie)* 8500/100,0) AS stock_categorie
	
	FROM volume_vendu vv
)


SELECT 
--Volume reference en % volume catégorie
	categorie,
	reference_produit,
	stock_categorie,
	-- 1. Volume vendu de chaque reference en % du volume vendu de sa catégorie
	ROUND(
	((volume_vendu_total::NUMERIC)*100)/ SUM(volume_vendu_total) OVER (PARTITION BY sa.categorie),10) AS pct_volume_categorie,

	-- 2. Calcul du stock alloué à la référence

	ROUND(
		(stock_categorie * (volume_vendu_total::NUMERIC))/ SUM(volume_vendu_total) 
		OVER (
		PARTITION BY sa.categorie)
	) AS stock_reference,


	volume_vendu_semaine,

	-- 3. Calcul du cycle de réapprovisionnement 

	ROUND((
		(stock_categorie * (volume_vendu_total::NUMERIC))/ SUM(volume_vendu_total) 
		OVER (
		PARTITION BY sa.categorie)) / volume_vendu_semaine,2
		) AS cycle_reapprovisionnement_semaines

FROM stock_alloue sa
;

------------------------------------------------------------
------- 2. Immobilisation du capital
------------------------------------------------------------

-- Calcul du stock immobilisé :

WITH volume_vendu AS (
    -- Calcul du volume total vendu et du pourcentage du volume global pour chaque produit
    SELECT
        dp.categorie,
        dp.reference_produit,
        fv.produit_id,
        SUM(fv.quantite_vendue) AS volume_total_vendu_3ans,
        -- Calcul du pourcentage du volume total de ventes
        ROUND((SUM(fv.quantite_vendue) * 100.0) / SUM(SUM(fv.quantite_vendue)) OVER () , 2) AS pct_volume_total_
    FROM fact_ventes fv
    LEFT JOIN dim_produits dp ON dp.produit_id = fv.produit_id
    GROUP BY dp.categorie, dp.reference_produit, fv.produit_id
),
-- Calcul final du stock par référence en utilisant des fenêtres
stock_optmial AS (
	SELECT
	    reference_produit,
	    ROUND(
	        (
	            -- 1. Calcul du Stock Catégoriel (Base 8500 unités)
	            SUM(pct_volume_total_) OVER (PARTITION BY categorie) * 8500 / 100
	        )
	        *
	        (
	            -- 2. Répartition proportionnelle du stock catégoriel au produit
	            volume_total_vendu_3ans::NUMERIC / 
	            SUM(volume_total_vendu_3ans) OVER (PARTITION BY categorie)
	        )
	    ) AS stock_reco
	FROM volume_vendu
	ORDER BY categorie, reference_produit
)


SELECT   
	dp.categorie,
	dp.reference_produit,
	
	-- stock en surplus 
	sa.stock_actuel - so.stock_reco AS stock_immobilise,

	-- cout du stock en surplus
	ROUND((sa.stock_actuel::NUMERIC - so.stock_reco::NUMERIC)* dp.cout::NUMERIC,1) AS cout_stock_immobilise,
	
	-- Coût d'opportunité annuel (Impact Marge)
ROUND(
    (sa.stock_actuel::NUMERIC - so.stock_reco::NUMERIC) 
    * dp.cout::NUMERIC 
    * 0.20, -- 20% de taux de possession annuel (inclut capital, assurance, obsolescence)
1) AS cout_possession_annuel
	
FROM stock_actuel sa

LEFT JOIN dim_produits dp ON dp.reference_produit = sa.reference_produit
LEFT JOIN stock_optmial so ON sa.reference_produit=so.reference_produit

--WHERE sa.stock_actuel > so.stock_reco
ORDER BY cout_stock_immobilise DESC

;

-- Cout total du stockage actuel

select 
	dim_produits.categorie,
	AVG(dim_produits.cout) AS cout_moyen,
	SUM(stock_actuel.stock_actuel) AS stock_actuel_cat,
	AVG(dim_produits.cout) * SUM(stock_actuel.stock_actuel) AS cout_moyen_cat_stocke

from dim_produits
INNER JOIN stock_actuel
	ON stock_actuel.reference_produit = dim_produits.reference_produit

GROUP BY dim_produits.categorie; 


------- Cout total du stockage recommandé

WITH volume_vendu AS (
		SELECT
		    categorie,
		    SUM(quantite_vendue) AS volume_total_vendu,
			ROUND(((SUM(quantite_vendue) * 100.0)/SUM(SUM(quantite_vendue)) OVER ())::NUMERIC, 2) AS pct_volume_total,
			AVG(cout) AS cout_moyen
				  
		FROM fact_ventes
		LEFT JOIN dim_produits
		    ON dim_produits.produit_id = fact_ventes.produit_id
		GROUP BY categorie
)

SELECT 
	categorie,
	cout_moyen,
	ROUND((pct_volume_total * 8500)/100,0) AS stock_a_prevoir,
	cout_moyen * ROUND((pct_volume_total * 8500)/100,0) AS cout_moyen_cat_stocke
FROM 

volume_vendu;




