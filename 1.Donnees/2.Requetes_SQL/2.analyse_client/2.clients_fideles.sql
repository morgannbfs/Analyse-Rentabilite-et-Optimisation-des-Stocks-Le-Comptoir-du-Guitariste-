-- ANALYSE CLIENTS 
--- 2. ETUDE DES CLIENTS FIDELES 
------- 1.Contribution au CA

------- 2. Analyse des achats
-------- 2.1. dernier panier
-------- 2.2 Nombre d'achat des clients champions dans chaque catégorie

------- 3. Contribution à la marge

------------------------------------------------------------
------- 1.Contribution au CA
------------------------------------------------------------

---------- 1.3 Contribution au CA des clients tres fideles
-- On isole le dernier quartile des clients par fréquence d'achat pour identifier son poids dans le CA

WITH 

		F AS (
				SELECT 
						dim_clients.client_id,			
						-- Nombre de transactions effectuées par client (Frequence):
						COUNT(fact_ventes.date_transaction) AS nombre_transactions,
						SUM(chiffre_affaire_transaction) AS total_CA_client
						
				FROM dim_clients
				
				LEFT JOIN fact_ventes
					ON fact_ventes.client_id = dim_clients.client_id
				
				GROUP BY dim_clients.client_id
			
		),
		-- identification des quartiles de la fréquence : 
		scores AS (
		
			SELECT 
				client_id,
				total_CA_client,
				-- Quartiles de fréquence : Q1 = plus petites valeurs (fréquences les plus faibles):
				NTILE(4) OVER( ORDER BY(nombre_transactions) ASC) AS frequency_q
		
			FROM F 
			
		),
		-- identification du CA par quartile :
		ca_by_quartile AS (
		    SELECT 
		        frequency_q,
		        SUM(total_ca_client::NUMERIC) AS CA_segment
		    FROM scores
		    GROUP BY frequency_q
		),
		
		-- CA total :
		ca_total AS (
			SELECT 
		
				SUM(total_ca_client::NUMERIC) AS CA_q
				
			FROM scores

		)
-- Requete finale pour identifier le CA par quartile : 	
SELECT 
	
	a.CA_segment*100/b.CA_q AS proportion_CA,
	a.frequency_q

FROM ca_by_quartile a
CROSS JOIN ca_total b 
	 
ORDER BY frequency_q DESC
;


------------------------------------------------------------
------- 2. Analyse des achats
------------------------------------------------------------
-- On identifie la proportion d'accessoires dans les achats de chaque quartile de fréquence.
-- La vente d'accessoires permet de mesurer la récurrence d'achat de produits consommables ou complémentaires, source de revenu stable. 
-- Proportion d'accessoires = Nombre de transactions Q4 pour des accessoires / Nombre total transactions Q4

-- On reprend les CTE F et scores de la requete précedente :
WITH 

		F AS (
				SELECT 
						dim_clients.client_id,			
						-- Nombre de transactions effectuées par client (Frequence):
						COUNT(fact_ventes.date_transaction) AS nombre_transactions,
						SUM(chiffre_affaire_transaction) AS total_CA_client
						
				FROM dim_clients
				
				LEFT JOIN fact_ventes
					ON fact_ventes.client_id = dim_clients.client_id
				
				GROUP BY dim_clients.client_id
			
		),
		-- identification des quartiles de la fréquence : 
		scores AS (
		
			SELECT 
				client_id,
				total_CA_client,
				-- Quartiles de fréquence : Q1 = plus petites valeurs (fréquences les plus faibles):
				NTILE(4) OVER( ORDER BY(nombre_transactions) ASC) AS frequency_q
		
			FROM F 
			
		),

		-- identification du nombre de transactions total et pour la catégorie 'Accessoire'
		transactions_q4 AS (

			SELECT 
				--Numérateur : Nombre de transaction pour les acessoires			
				--Agrégation conditionnelle pour compter directement le nombre d'accessoires dans SELECT :
				SUM(CASE 
						WHEN dim_produits.categorie IN ('Guitare Folk', 'Guitare Electrique') THEN 0
						ELSE 1
				END) AS segment_produit,

				-- Dénominateur : Nombre total de transactions
				COUNT(fact_ventes.order_id) AS total_transactions
				
			FROM fact_ventes
			INNER JOIN scores
				ON scores.client_id = fact_ventes.client_id

			INNER JOIN dim_produits
				ON dim_produits.produit_id = fact_ventes.produit_id

				
			WHERE 
				frequency_q = 4

		)

-- Requete finale pour identifier le % d'accessoires dans les ventes des 25% des clients les plus loyaux :
SELECT 
	ROUND((segment_produit::NUMERIC/ total_transactions)*100,2) AS accessoires_q4

	FROM transactions_q4

;

------- 2.2. Nombre d'achat des clients champions dans chaque catégorie : 

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


-- Nombre d'achat des clients champions dans chaque catégorie : 
SELECT 
	dim_produits.categorie,

	SUM(fact_ventes.quantite_vendue) AS nb_achats_champions

FROM scores

INNER JOIN fact_ventes ON scores.client_id = fact_ventes.client_id
INNER JOIN dim_produits ON fact_ventes.produit_id = dim_produits.produit_id

WHERE 
	recency_q IN (3,4)
	AND frequency_q IN (3,4)
	AND monetary_q IN (3,4)

GROUP BY 
	dim_produits.categorie
ORDER BY 
	nb_achats_champions DESC
	
	;

------------------------------------------------------------
------- 3. Contribution à la marge
------------------------------------------------------------
-- On vérifie si les clients les plus loyaux sont ceux qui génèrenet le plus de marge : 

WITH 

		F AS (
				SELECT 
						dim_clients.client_id,			
						-- Nombre de transactions effectuées par client (Frequence):
						COUNT(fact_ventes.date_transaction) AS nombre_transactions,
						SUM(chiffre_affaire_transaction) AS total_CA_client
						
				FROM dim_clients
				
				LEFT JOIN fact_ventes
					ON fact_ventes.client_id = dim_clients.client_id
				
				GROUP BY dim_clients.client_id
			
		),
		-- identification des quartiles de la fréquence : 
		scores AS (
		
			SELECT 
				client_id,
				total_CA_client,
				-- Quartiles de fréquence : Q1 = plus petites valeurs (fréquences les plus faibles):
				NTILE(4) OVER( ORDER BY(nombre_transactions) ASC) AS frequency_q
		
			FROM F 
			
		),
		-- Calcul de la marge du Q4 :
		marge_q4 AS (
			SELECT 
				SUM (fv.marge_transaction::NUMERIC) AS marge_brute_q4
			
			FROM fact_ventes fv
			
			INNER JOIN dim_produits dp
				ON dp.produit_id = fv.produit_id
			
			INNER JOIN scores
				ON scores.client_id = fv.client_id
			
			WHERE frequency_q =4
		),
		-- Calcul de la marge brute totale 
		marge_totale AS (
        SELECT 
            SUM(fv.marge_transaction::NUMERIC) AS total_margin
        FROM fact_ventes fv
        INNER JOIN dim_produits dp
            ON dp.produit_id = fv.produit_id
			
		)

-- Requete finale : % de la marge généré par les clients les plus fidèles: 
SELECT 
	marge_brute_q4,
	total_margin,
	ROUND((m4.marge_brute_q4*100)/ mt.total_margin,2 )AS pct_marge_totale

FROM marge_q4 m4
CROSS JOIN marge_totale mt

;
