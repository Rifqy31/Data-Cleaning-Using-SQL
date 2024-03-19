/*

Cleaning Data Using SQL

*/

SELECT * FROM NashvilleHousing

-----------------------------------------------------------------------------------------------------------------------------------

--Standarized Date Format

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM NashvilleHousing

BEGIN TRANSACTION

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

SELECT SaleDate
FROM NashvilleHousing

COMMIT

-----------------------------------------------------------------------------------------------------------------------------------

--Add a Value to Null columns in Property Address Data

SELECT * 
FROM NashvilleHousing
WHERE PropertyAddress is null

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NashvilleHousing a
JOIN NashvilleHousing b 
ON a.ParcelID = b.ParcelID 
    and a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null

/*

Using query above we could see that there are same parcel id but the property address is null.
So we fill null columns using property address that have the same parcel id

*/

BEGIN TRANSACTION

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b 
ON a.ParcelID = b.ParcelID 
    and a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null

--Before Commiting, Check the table if there is still null value in Property address

COMMIT

-----------------------------------------------------------------------------------------------------------------------------------

--Split Address Into Different Columns (Address, City, State)

SELECT PropertyAddress
FROM NashvilleHousing

/*

Split Property Address into 2 columns (Address and City)
Using SUBSTRING to find the Address and City 
Using CHARINDEX to find delimiter

*/

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address
FROM NashvilleHousing

--Query above will result only the address of the property

SELECT SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress)) AS City
FROM NashvilleHousing

--Query above will result only the City of the property

/*

After we find property address and city, we add new columns for them.
Using Alter to add new column to NashvilleHousing table

*/

Begin TRANSACTION

--Address
ALTER TABLE NashvilleHousing
ADD Property_Address NVARCHAR(200)

UPDATE NashvilleHousing
SET Property_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

SELECT Property_Address 
FROM NashvilleHousing


--City
ALTER TABLE NashvilleHousing
ADD PropertyCity NVARCHAR(200)

UPDATE NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress))

SELECT Property_Address, PropertyCity
FROM NashvilleHousing

--Now we have succeeded on splitting address and city from PropertyAddress and create new column for it

COMMIT

SELECT SUBSTRING(OwnerAddress, 1, CHARINDEX(',', OwnerAddress) -1),
SUBSTRING(OwnerAddress, CHARINDEX(',', OwnerAddress), CHARINDEX(',', OwnerAddress))
FROM NashvilleHousing
/*

Now for OwnerAddress.
Because there are two commas in OwnerAddress we could use substring but it's too complicated.
Instead, we could use PARSENAME. 
PARESNAME is used to find '.' and return the value after '.' in the column we want to see.
But there is no '.' in OwnerAddress so we replace the comma with period.

*/

SELECT PARSENAME(REPLACE(OwnerAddress,',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)
FROM NashvilleHousing

--After we separate the address, city, and state, same as before we add new column and update the value

BEGIN TRANSACTION

ALTER TABLE NashvilleHousing
ADD Owner_Address NVARCHAR(200)

UPDATE NashvilleHousing
SET Owner_Address = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD Owner_City NVARCHAR(200)

UPDATE NashvilleHousing
SET Owner_City = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD Owner_State NVARCHAR(200)

UPDATE NashvilleHousing
SET Owner_State = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)

SELECT Owner_Address, Owner_City, Owner_State
FROM NashvilleHousing

COMMIT

-----------------------------------------------------------------------------------------------------------------------------------

--Change the Y and N to Yes and No in SoldAsVacant

SELECT DISTINCT(SoldAsVacant)
FROM NashvilleHousing

--Use Case to replace the Y and N

SELECT SoldAsVacant,
CASE    WHEN SoldAsVacant = 'Y' then 'Yes'
        WHEN SoldAsVacant = 'N' then 'No'
        ELSE SoldAsVacant
        END
FROM NashvilleHousing

--After we check it and everything looks great, we update the column

Begin TRANSACTION

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' then 'Yes'
        WHEN SoldAsVacant = 'N' then 'No'
        ELSE SoldAsVacant
        END

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS Total
FROM NashvilleHousing
Group BY SoldAsVacant
Order By Total DESC

COMMIT


-----------------------------------------------------------------------------------------------------------------------------------


--Remove Duplicate

/*

To find a duplicate row we could use row number to identify the duplicate row if row number is bigger than 1.

*/

BEGIN TRANSACTION
/*

Because we can't use 'WHERE row_num > 2', 
we use CTE to make a temporary table as we execute the query.
By using the CTE we can identify how many duplicate row in NashvilleHousing table.

*/

WITH RowCTE AS(
    SELECT *, ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                 PropertyAddress,
                 SaleDate,
                 SalePrice,
                 LegalReference
                 Order BY UniqueID 
    ) as row_num
    FROM NashvilleHousing
    -- ORDER BY ParcelID
)

SELECT *
FROM RowCTE
WHERE row_num > 1

DELETE
FROM RowCTE
WHERE row_num > 1

COMMIT

--There are 104 rows of duplicated value. Then we could delete the row using DELETE FROM RowCTE


-----------------------------------------------------------------------------------------------------------------------------------

--Delete unused columns

SELECT *
FROM NashvilleHousing

/*

The column that will going to be deleted are PropertyAddress, OwnerAddress, and TaxDistrict

PropertyAdress
The reason we delete this column because we already split the address into two column (address and city),
so we don't need it anymore

OwnerAddress
Same as PropertyAddress, we have split the OwnerAddres into three new colum (address, city, and state).

TaxDistrict
We don't need the TaxDistrict in this table

*/

Begin TRANSACTION

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict

SELECT * 
FROM NashvilleHousing

COMMIT
