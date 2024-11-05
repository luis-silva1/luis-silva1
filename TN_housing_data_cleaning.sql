
-- Standardized Date --------------------------------------------------------------------------------
Select SaleDate, STR_TO_DATE(REPLACE(SaleDate, ',', ''), "%M %d %Y") AS new_SalesDate
FROM housing_data;

ALTER TABLE housing_data
ADD UpdatedSalesDate DATE;

UPDATE housing_data
SET UpdatedSalesDate = STR_TO_DATE(REPLACE(SaleDate, ',', ''), "%M %d %Y");



-- Update NULL PropertyAddress values that have the same ParcelID but not NULL Values
SELECT *
FROM housing_data AS hd1
JOIN housing_data AS hd2
	ON hd1.ParcelID = hd2.ParcelID
    AND hd1.UniqueID <> hd2.UniqueID
WHERE hd1.PropertyAddress IS NULL;

-- Breaking out address into individual columns --------------------------------------------------------------------------------
SELECT PropertyAddress, 
		SUBSTRING_INDEX(PropertyAddress, ',', 1) AS Street_Address,
   		TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1)) AS trim_City
FROM housing_data;

ALTER TABLE housing_data
ADD Street_Address VARCHAR(255);

UPDATE housing_data
SET Street_Address = SUBSTRING_INDEX(PropertyAddress, ',', 1);

ALTER TABLE housing_data
ADD City VARCHAR(255);

UPDATE housing_data
SET City = TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1));

-- Updating/Splitting Owner Address
SELECT OwnerAddress, 
		SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Owner_street_address,
   		TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1)) AS Owner_State,
		TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1)) AS Owner_City
FROM housing_data;

ALTER TABLE housing_data
ADD Owner_street_address VARCHAR(255);

UPDATE housing_data
SET Owner_street_address = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1));

ALTER TABLE housing_data
ADD Owner_state VARCHAR(255);

UPDATE housing_data
SET Owner_state = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));

ALTER TABLE housing_data
ADD Owner_city VARCHAR(255);

UPDATE housing_data
SET Owner_city = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1));


-- ALTER DATA for consistent standardization --------------------------------------------------------------------------------
SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
         ELSE SoldAsVacant
         END AS updated_SoldAsVacant
FROM housing_data;

UPDATE housing_data
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
         ELSE SoldAsVacant
         END;


-- Removing Duplicates --------------------------------------------------------------------------------
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, 
									PropertyAddress,
                                    SalePrice,
                                    SaleDate,
                                    LegalReference
                                    ORDER BY UniqueID) AS row_num
FROM housing_data
)
DELETE 
FROM housing_data
WHERE UniqueID IN(SELECT UniqueID
				  FROM RowNumCTE 
                  WHERE row_num >1);


-- Delete Unused Columns
SELECT *
FROM housing_data;

ALTER TABLE housing_data
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress;

ALTER TABLE housing_data
DROP COLUMN SaleDate;


