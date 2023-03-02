/* Data Cleaning
to use the named database as the default*/
USE [Portfolio];

--------------------------------------------------------------------------------------------------------------------------
--Standartize Date Format

SELECT [SaleDate],
       convert(date,[SaleDate])
FROM [dbo].[NashvilleHousing];


ALTER TABLE [dbo].[NashvilleHousing]
ALTER COLUMN [SaleDate] date;

--------------------------------------------------------------------------------------------------------------------------
--Populate Property address data

SELECT *
FROM [dbo].[NashvilleHousing]
WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

SELECT a.[ParcelID],
       a.[PropertyAddress],
       b.[ParcelID],
       b.[PropertyAddress],
       ISNULL(a.[PropertyAddress], b.[PropertyAddress])
FROM [dbo].[NashvilleHousing] a
JOIN [dbo].[NashvilleHousing] b ON a.[ParcelID]=b.[ParcelID]
AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET [PropertyAddress] = ISNULL(a.[PropertyAddress], b.[PropertyAddress])
FROM [dbo].[NashvilleHousing] a
JOIN [dbo].[NashvilleHousing] b ON a.[ParcelID] = b.[ParcelID]
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.[PropertyAddress] IS NULL;

--------------------------------------------------------------------------------------------------------------------------
-- Breaking out Property/Owner Address into Individual Columns (Address, City, State)

SELECT SUBSTRING([PropertyAddress], 1, charindex(',', [PropertyAddress])-1) AS Address,
       SUBSTRING([PropertyAddress], charindex(',', [PropertyAddress])+1, LEN([PropertyAddress])) AS City
FROM [dbo].[NashvilleHousing];

ALTER TABLE [dbo].[NashvilleHousing] ADD 
	PropertySplitAddress nvarchar(255),
    ProprtySplitCity nvarchar(255);

UPDATE [dbo].[NashvilleHousing]
SET [PropertySplitAddress]=SUBSTRING([PropertyAddress], 1, charindex(',', [PropertyAddress])-1),
    [ProprtySplitCity]=SUBSTRING([PropertyAddress], charindex(',', [PropertyAddress])+1, LEN([PropertyAddress]));

SELECT Parsename(replace([OwnerAddress], ',', '.'), 3),
       Parsename(replace([OwnerAddress], ',', '.'), 2),
       Parsename(replace([OwnerAddress], ',', '.'), 1)
FROM [dbo].[NashvilleHousing];

ALTER TABLE [dbo].[NashvilleHousing] ADD 
	OwnerSplitAddress nvarchar(255),
    OwnerSplitCity nvarchar(255),
    OwnerSplitState nvarchar(10);

UPDATE [dbo].[NashvilleHousing]
SET [OwnerSplitAddress]=Parsename(replace([OwnerAddress], ',', '.'), 3),
    [OwnerSplitCity]=Parsename(replace([OwnerAddress], ',', '.'), 2),
    [OwnerSplitState]=Parsename(replace([OwnerAddress], ',', '.'), 1);

--------------------------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT Distinct([SoldAsVacant]),
       Count([SoldAsVacant])
FROM [dbo].[NashvilleHousing]
GROUP BY [SoldAsVacant]
ORDER BY 2

UPDATE [dbo].[NashvilleHousing]
SET [SoldAsVacant]=CASE
                       WHEN [SoldAsVacant]= 'Y' THEN 'Yes'
                       WHEN [SoldAsVacant]= 'N' THEN 'No'
                       ELSE [SoldAsVacant]
                   END

--------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates(if needed)

WITH rnCTE AS
  (SELECT *,
          ROW_NUMBER() OVER (PARTITION BY [ParcelID],
                                          [PropertyAddress],
                                          [SalePrice],
                                          [SaleDate],
                                          [LegalReference]
                             ORDER BY [UniqueID ]) row_numb
   FROM [dbo].[NashvilleHousing])
DELETE
FROM rnCTE
WHERE row_numb>1


--------------------------------------------------------------------------------------------------------------------------
-- Delete Columns that were broken down(Property/Owner Address_

ALTER TABLE [dbo].[NashvilleHousing]
DROP COLUMN [OwnerAddress],
            [PropertyAddress]