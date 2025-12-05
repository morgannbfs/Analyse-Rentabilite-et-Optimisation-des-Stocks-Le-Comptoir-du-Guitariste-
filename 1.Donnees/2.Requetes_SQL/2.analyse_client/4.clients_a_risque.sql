-- ANALYSE CLIENTS 
--- 3. ETUDE DES CLIENTS A RISQUE
------- 1. Quantification du Risque
------- 2. Analyse des achats par catégorie


------------------------------------------------------------
------- 1. Identification de la cible "Client a Risque"
------------------------------------------------------------
-- Création de chaque catégorie R-F-M:
WITH 

RFM AS (
		SELECT 
				dim_clients.client_id,
				--Dernière transaction de chaque client (Recence):
				'2024-12-31' - MAX(fact_ventes.date_transaction) AS jours_depuis_derniere_transaction,
				
				-- Nombre de transactions effectuées par client (Frequence):
				COUNT(fact_ventes.date_transaction) AS nombre_transactions,
		
				-- Achat moyen par client (Monetaire) :
				COALESCE(SUM(COALESCE(chiffre_affaire_transaction,0)),0)/NULLIF(COUNT(fact_ventes.date_transaction),0) AS achat_moyen
				
		FROM dim_clients
		
		LEFT JOIN fact_ventes
			ON fact_ventes.client_id = dim_clients.client_id
		
		GROUP BY dim_clients.client_id
	
),

scores AS (

	SELECT 
		client_id,
		-- On divise la recence en quartiles en mettant en Q1 les plus grandes valeurs (recences les plus faibles ):
		CONCAT (
				NTILE(4) OVER( ORDER BY(jours_depuis_derniere_transaction) DESC),
				-- On divise la fréquence en quartiles en mettant en Q1 les plus petites valeurs (fréquences les plus faibles):
				NTILE(4) OVER( ORDER BY(nombre_transactions) ASC),
				-- On divise l'achat moyen en quartiles en mettant en Q1 les plus petites valeurs (achats moyens les plus faibles):
				NTILE(4) OVER(ORDER BY (achat_moyen) ASC))
				
		 as score_rfm

	FROM RFM
),

segments AS (
--Classement des clients en 5 czatégories selon leurs scores RFM:
SELECT 
	COUNT(client_id) AS nombre_clients,
		 
	CASE 
		-- 1. Les Meilleurs (Champions)
        WHEN score_rfm BETWEEN '333' AND '444' THEN '1 - Champion' 
        
        -- 2. Les Fidèles Dormants (Urgence Récence)
        WHEN score_rfm IN ( '133','134','143','144','233','234', '243','244') THEN '2 - Champion Hibernant' 
        
        -- 3. Les Nouveaux / Potentiels (Développer F et M)
        WHEN score_rfm IN ('411', '412', '421', '422', '311', '322') THEN '3 - Nouveau/Potentiel' 
        
        -- 4. Les Clients Client a Risque (Maintenir l'engagement)
        WHEN score_rfm BETWEEN '222' AND '332' THEN '4 - Client a Risque'
        
        -- 5. Les Clients Perdus (Tenter la réactivation)
        WHEN score_rfm BETWEEN '111' AND '221' THEN '5 - Client Perdu' 

        ELSE '6 - Autres (À Réviser)' -- Couvre les cas marginaux non définis
    END AS segment_strategique

FROM Scores
GROUP BY segment_strategique

)

select
	*
FROM segments
where segment_strategique = '4 - Client a Risque'
;


------------------------------------------------------------
------- 2. Analyse des achats par catégorie
------------------------------------------------------------
-- Le but est de comprendre l'historique d'achat de ces champions hibernants pour savoir quel type d'offre sera efficace pour une relance.

WITH
RFM AS (
			SELECT 
					dim_clients.client_id,
					-- Recence:
					'2024-12-31' - MAX(fact_ventes.date_transaction) AS jours_depuis_derniere_transaction,
					-- Frequence:
					COUNT(fact_ventes.date_transaction) AS nombre_transactions,
					-- Monetaire:
					COALESCE(SUM(COALESCE(chiffre_affaire_transaction,0)),0)/NULLIF(COUNT(fact_ventes.date_transaction),0) AS achat_moyen
					
			FROM dim_clients
			LEFT JOIN fact_ventes
				ON fact_ventes.client_id = dim_clients.client_id
			GROUP BY dim_clients.client_id
			
),
-- Création des scores pour chaque catégorie:
		scores AS (
			SELECT 
				client_id,
				-- Quartiles de recence:
				NTILE(4) OVER( ORDER BY(jours_depuis_derniere_transaction) DESC) AS recency_q,
				-- Quartiles de fréquences:
				NTILE(4) OVER( ORDER BY(nombre_transactions) ASC) AS frequency_q,
				-- Quartiles de monetaire:
				NTILE(4) OVER(ORDER BY (achat_moyen) ASC) AS monetary_q
		
			FROM RFM
)

-- Nombre de champions hibernants ayant acheté dans chaque catégorie : 

SELECT 
	dim_produits.categorie,
	SUM(fact_ventes.quantite_vendue) AS nb_achats_champions_hibernants

FROM scores

INNER JOIN fact_ventes ON scores.client_id = fact_ventes.client_id
INNER JOIN dim_produits ON fact_ventes.produit_id = dim_produits.produit_id

WHERE 
	recency_q IN (1,2)
	AND frequency_q IN (3,4)
	AND monetary_q IN (3,4)

GROUP BY 
	dim_produits.categorie
ORDER BY 
	nb_achats_champions_hibernants DESC
	
	;


























