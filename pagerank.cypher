/* Creating constraints so users and products are all unique */
CREATE CONSTRAINT FOR (u:User)
REQUIRE (u.user_id) IS UNIQUE;

CREATE CONSTRAINT FOR (p:Product)
REQUIRE (p.product_id) IS UNIQUE;

/* Loading in data for user nodes, product nodes, and rating relationships */
LOAD CSV WITH HEADERS FROM 'file:///transactions_brand(users).csv' AS row
MERGE (u:User { user_id: row.user_id });

LOAD CSV WITH HEADERS FROM 'file:///transactions_brand(products).csv' AS row
MERGE (p:Product { product_id: row.product_id })
SET p.product_name = row.product_name,
    p.category     = row.category,
    p.brand        = row.brand,
    p.release_date = row.release_date;
    
LOAD CSV WITH HEADERS FROM 'file:///transactions_brand(ratings).csv' AS row
MATCH (u:User { user_id: row.user_id })
MATCH (p:Product { product_id: row.product_id })
MERGE (u)-[r:RATED]->(p)
SET r.rating = toFloat(row.rating);

/* Create graph projection */
CALL gds.graph.project(
  'userProductGraph',
  ['User', 'Product'],
  {
    RATED: {
      type: 'RATED',
      orientation: 'UNDIRECTED',
      properties: ['rating']
    }
  }
);

/* Compute page rank */
CALL gds.pageRank.write(
  'userProductGraph',
  {
    maxIterations: 50,
    dampingFactor: 0.85,
    writeProperty: 'pageRank',
    relationshipWeightProperty: 'rating'
  }
);

RETURN rec.product_id, rec.product_name, rec.brand, score;

/* Given a target user, recommend products */
WITH 'AEAMIR3CMSA32IDEINSJKHRNANTA' AS targetUser

MATCH (u:User {user_id: 'AEAMIR3CMSA32IDEINSJKHRNANTA'})-[:RATED]->(p:Product)
WITH u, COLLECT(DISTINCT p.brand) AS preferred_brands

/* Find recommended products */
// Exclude already rated products
MATCH (rec:Product)
WHERE NOT EXISTS { (u)-[:RATED]->(rec) }

// Compute Brand Similarity Score
WITH rec, preferred_brands, 
    CASE WHEN rec.brand IN preferred_brands THEN 1 ELSE 0.5 END AS brand_score

// Compute Collaborative Filtering Score
OPTIONAL MATCH (other:User)-[r:RATED]->(rec)
WHERE EXISTS { MATCH (u)-[:RATED]->(p:Product)<-[:RATED]-(other) }
WITH rec, brand_score, COALESCE(AVG(r.rating), 0) AS avg_rating, rec.pageRank AS page_rank

// Weighted Score
WITH rec, 
     page_rank * 0.5 + avg_rating * 0.3 + brand_score * 0.2  AS score
RETURN rec.product_id, rec.product_name, rec.brand, score
ORDER BY score DESC
LIMIT 5;