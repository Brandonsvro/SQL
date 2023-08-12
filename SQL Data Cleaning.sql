
--Cleaning Data in SQL Series

SELECT * FROM NashvilleHousing
ORDER BY 2;


--Standardize Date Format

SELECT SaleDateConvert, CONVERT(date,SaleDate)
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(date,SaleDate)   --Harusnya jalan tapi gatau kenapa ga ke ubah

ALTER TABLE NashvilleHousing  -- Cara lain, kita tambahin kolom baru dulu baru update kolom barunya
ADD SaleDateConvert date;

UPDATE NashvilleHousing
SET SaleDateConvert = CONVERT(date,SaleDate)  --SELECT * FROM NashvilleHousing Berhasil


--Populate Property Address Data

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing as a
JOIN NashvilleHousing as b
ON a.ParcelID = b.ParcelID
and a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null          -- kita self join karna parcel id nya sama, jadi kita asumsi alamatnya sama

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing as a
JOIN NashvilleHousing as b
ON a.ParcelID = b.ParcelID
and a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null


--Breaking Out PropertyAddress Into Individual Column (Address, City)

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1),
		SUBSTRING(PropertyAddress, (CHARINDEX(',', PropertyAddress)+1), LEN(PropertyAddress))
FROM NashvilleHousing


ALTER TABLE NashvilleHousing
ADD PropertySplitAddress varchar(255)

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity varchar(255)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, (CHARINDEX(',', PropertyAddress)+1), LEN(PropertyAddress))



-- Breaking Out OwnerAddress Into Individual Column (Address, City, State)

SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing


ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress varchar(255)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity varchar(255)

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState varchar(255)

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


-- Change "Y" and "N" to "Yes" and "No" in SoldAsVacant

SELECT CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldASVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldASVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END


-- Remove Duplicate Data

With RowNumCTE as(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY ParcelID,
			 PropertyAddress,
			 SaleDate,
			 SalePrice,
			 LegalReference
			 ORDER BY UniqueID) as RowNum
FROM NashvilleHousing)

DELETE 
FROM RowNumCTE
WHERE RowNum > 1


-- Delete Unused Columns

ALTER TABLE NashvilleHousing
DROP COlUMN PropertyAddress,
			SaleDate,
			OwnerAddress,
			TaxDistrict

SELECT * FROM NashvilleHousing