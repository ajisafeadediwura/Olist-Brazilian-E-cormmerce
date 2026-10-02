# Olist-Brazillian-E-cormmerce
Olist is an e-cormmerce marketplace. Management wants to know how sales are growing, which categories drive revenue, how reliable delivery is, and whether customers come back.
# Data Source
The dataset used for this project is the **Brazilian E-commerce Public Dataset by Olist**, hosted on Kaggle. It contains information on 100k orders from 2016 to 2018 made across multiple marketplaces in Brazil.
* **Dataset Link** [Kaggle - Brazilian E-commerce Public Dataset] (https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
* **Data Provider:** Olist

### Setup Instructions
1. Download the raw CSV files from the Kaggle link above.
2. Place the unzipped CSV files into your local directory (e.g., 'C:\sql\olist\').
3. Run the 'database_setup.sql' script to build the Bronze, Silver, and Gold layers.


### How to reproduce
1. Download the dataset from Kaggle and place the CSV files in C:\sql\olist\
   (or edit the paths in sql/00_setup/02_load_bronze_procedure.sql).
2. Run 01_ddl_bronze.sql.
3. Run 02_load_bronze_procedure.sql, then EXEC bronze.load_bronze;
4. Load olist_order_reviews_dataset.csv with the SSMS Import Flat File wizard
   into bronze.order_reviews (all columns as nvarchar, schema bronze).
   See docs/04_methodology.md for why.
