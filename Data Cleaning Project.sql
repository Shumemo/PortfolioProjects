/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM Portfolio.dbo.NashvilleHousing

-----------------------------------------

-- Standardize Date Format

-- This is the format I want.
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM Portfolio.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

-- It didn't update with this, curious, lets try another method...
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-- Double-check...
SELECT *
FROM Portfolio.dbo.NashvilleHousing

-- Looks good!

-----------------------------------------

-- Populate Property Address Data
SELECT *
FROM Portfolio.dbo.NashvilleHousing

-- ParcelID and PropertyAddress seems to be linked.
-- Specific ParcelID always has a specific PropertyAddress linked to it.
SELECT *
FROM Portfolio.dbo.NashvilleHousing
ORDER BY ParcelID

-- We can join the same table to itself, using only the UniqueID with the ParcelID, because the SaleDate might be different for the same PropertyAddress, and the UniqueID is unique.
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM Portfolio.dbo.NashvilleHousing a
JOIN Portfolio.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Now I can see the NULL PropertyAddresses, we can use the PropertyAddress that is listed in the b table to fill in the a table PropertyAddress to clean up the NULLs
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio.dbo.NashvilleHousing a
JOIN Portfolio.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio.dbo.NashvilleHousing a
JOIN Portfolio.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Check if it worked.
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio.dbo.NashvilleHousing a
JOIN Portfolio.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- It worked, because we see no NULL rows listed now.
-- Looks good!

-----------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)
SELECT PropertyAddress
FROM Portfolio.dbo.NashvilleHousing

--

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) as Address
FROM Portfolio.dbo.NashvilleHousing

-- Lets remove the comma.
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
FROM Portfolio.dbo.NashvilleHousing

-- And moving on...
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address 
FROM Portfolio.dbo.NashvilleHousing

-- Add table.
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

-- Add results.
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

-- Add table of city.
ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

-- Add substring of city.
UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- Checking
SELECT *
FROM Portfolio.dbo.NashvilleHousing

-- This splitting the address and the city makes this dataset MUCH more usable.
-- I will aim to do similar to OwnerAddress using another method.

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM Portfolio.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);
ADD OwnerSplitCity Nvarchar(255);
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT *
FROM Portfolio.dbo.NashvilleHousing

-- Looks much more usable now.

-----------------------------------------

-- Changing the Y and N to Yes and No in 'Sold as Vacant' field.

SELECT Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM Portfolio.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM Portfolio.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END

-- Double Check.
SELECT Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM Portfolio.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-----------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY PARCELID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM Portfolio.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- There are 104 duplicates.

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY PARCELID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM Portfolio.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

-- Checking

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY PARCELID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM Portfolio.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- Duplicates removed.

-----------------------------------------

-- Delete Unused Columns
-- NOTE THIS IS NOT STANDARD PRACTICE, YOU GENERALLY NEVER DELETE FROM RAW DATA UNLESS SPECIFICALLY TOLD
-- This is strictly to get what was asked for from the dataset by the client.

SELECT *
FROM Portfolio.dbo.NashvilleHousing

-- I separated these columns into a more usable format, and removing others not needed for future analysis.
ALTER TABLE Portfolio.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

-- Final Check
SELECT *
FROM Portfolio.dbo.NashvilleHousing

-- Looks clean!

-- FINISHED.