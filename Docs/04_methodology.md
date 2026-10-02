## Bronze layer: loading decisions and issues

All bronze columns are stored as text (nvarchar) so that no row is rejected on
load. Type conversion happens in the silver layer.

| Issue | Symptom | Cause | Fix |
|---|---|---|---|
| Wrong line endings | Msg 4866: column too long for row 1, column 5 | Files end lines with \n, but SQL Server expects \r\n by default | Added ROWTERMINATOR = '0x0a' |
| Quoted values | Values would load with quote characters, breaking joins | Olist wraps text in double quotes | Used FORMAT = 'CSV' instead of FIELDTERMINATOR = ',' |
| Reviews file fails | Msg 7301 on order_reviews | Free-text comments contain line breaks, which BULK INSERT cannot read reliably | Loaded this one table with the SSMS Import Flat File wizard, all columns as text, schema bronze |
| Geolocation file | Not loaded | Not needed for the business questions; about 1M rows with repeated zip codes would risk duplicated joins | Excluded (can be added later for map visuals) |

Row counts after load are recorded in the README.
