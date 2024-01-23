CREATE DATABASE DWH_SRI_Recaudacion
USE DWH_SRI_Recaudacion

-- Dim_Fecha
CREATE TABLE Dim_Fecha (
    FechaID INT IDENTITY(1,1) NOT NULL,
    Año INT,
    Mes INT,
	Dia INT,
    MesLabel NVARCHAR(32),
	DiaSemana NVARCHAR(32),
	Trimestre INT, 

    CONSTRAINT PK_Dim_Fecha PRIMARY KEY (FechaID)
);


SELECT DISTINCT 
    YEAR(fecha) AS Anio,
    MONTH(fecha) AS Mes,
    DAY(fecha) AS Dia,
	UPPER(FORMAT(fecha, 'MMMM', 'es-ES')) AS MesLabel,
	UPPER(FORMAT(fecha, 'dddd', 'es-ES')) AS DiaSemana,
	DATEPART(QUARTER, fecha) AS Trimestre
FROM [STAGE_SRI].[dbo].[XLSSRI];


-- Dim_Impuesto
CREATE TABLE Dim_Impuesto (
    ImpuestoID INT IDENTITY(1,1) NOT NULL,
    Grupo_Impuesto NVARCHAR(64),
    Subgrupo_Impuesto NVARCHAR(64),
    Impuesto NVARCHAR(64),

    CONSTRAINT PK_Dim_Impuesto PRIMARY KEY (ImpuestoID)
);


SELECT DISTINCT
    COALESCE(NULLIF(LTRIM(RTRIM(GRUPO_IMPUESTO)), ''), 'No Especificado') AS Grupo_Impuesto,
    COALESCE(NULLIF(LTRIM(RTRIM(SUBGRUPO_IMPUESTO)), ''), 'No Especificado') AS Subgrupo_Impuesto,
    COALESCE(NULLIF(LTRIM(RTRIM(IMPUESTO)), ''), 'No Especificado') AS Impuesto
FROM [STAGE_SRI].[dbo].[XLSSRI]


-- Dim_Contribuyente
CREATE TABLE Dim_Contribuyente (
    ContribuyenteID INT IDENTITY(1,1) NOT NULL,
    Gran_Contribuyente NVARCHAR(2),
    Codigo_Opera_Familia NVARCHAR(32),
    Tipo_Contribuyente NVARCHAR(32),

	CONSTRAINT PK_Dim_Contribuyente PRIMARY KEY (ContribuyenteID)
);


SELECT DISTINCT
    COALESCE(NULLIF(LTRIM(RTRIM(GRAN_CONTRIBUYENTE)), ''), 'No Especificado') AS Gran_Contribuyente,
    COALESCE(NULLIF(LTRIM(RTRIM(CODIGO_OPERA_FAMILIA)), ''), 'No Especificado') AS Codigo_Opera_Familia,
    COALESCE(NULLIF(LTRIM(RTRIM(TIPO_CONTRIBUYENTE)), ''), 'No Especificado') AS Tipo_Contribuyente
FROM [STAGE_SRI].[dbo].[XLSSRI]


-- Dim_Ubicacion
CREATE TABLE Dim_Ubicacion (
    UbicacionID INT IDENTITY(1,1) NOT NULL,
    Provincia NVARCHAR(32),
    Region VARCHAR(32),

	CONSTRAINT PK_Dim_Ubicacion PRIMARY KEY (UbicacionID)
);


SELECT DISTINCT
    COALESCE(NULLIF(LTRIM(RTRIM(PROVINCIA)), ''), 'No Especificado') AS Provincia,
    CASE 
        WHEN PROVINCIA IN ('GUAYAS', 'SANTA ELENA', 'MANABI', 'ESMERALDAS', 'LOS RIOS', 'SANTO DOMINGO DE LOS TSÁCHILAS', 'EL ORO') THEN 'Costa'
        WHEN PROVINCIA IN ('PICHINCHA', 'AZUAY', 'LOJA', 'TUNGURAHUA', 'CHIMBORAZO', 'BOLIVAR', 'COTOPAXI', 'IMBABURA', 'CARCHI', 'CAÑAR') THEN 'Sierra'
        WHEN PROVINCIA IN ('SUCUMBIOS', 'ORELLANA', 'NAPO', 'PASTAZA', 'MORONA SANTIAGO', 'ZAMORA CHINCHIPE') THEN 'Oriente'
        WHEN PROVINCIA = 'GALAPAGOS' THEN 'Insular'
        ELSE 'NO TIENE'
    END AS Region
FROM [STAGE_SRI].[dbo].[XLSSRI]


-- Hecho_Recaudacion
CREATE TABLE Hecho_Recaudacion (
    FechaID INT NOT NULL,
    ImpuestoID INT NOT NULL,
    ContribuyenteID INT NOT NULL,
    UbicacionID INT NOT NULL,
    Valor_Recaudado FLOAT NOT NULL,

    CONSTRAINT FK_Hecho_Recaudacion_Fecha FOREIGN KEY (FechaID) REFERENCES Dim_Fecha(FechaID),
    CONSTRAINT FK_Hecho_Recaudacion_Impuesto FOREIGN KEY (ImpuestoID) REFERENCES Dim_Impuesto(ImpuestoID),
    CONSTRAINT FK_Hecho_Recaudacion_Contribuyente FOREIGN KEY (ContribuyenteID) REFERENCES Dim_Contribuyente(ContribuyenteID),
    CONSTRAINT FK_Hecho_Recaudacion_Ubicacion FOREIGN KEY (UbicacionID) REFERENCES Dim_Ubicacion(UbicacionID)
);


SELECT
    F.FechaID,
    I.ImpuestoID,
    C.ContribuyenteID,
    U.UbicacionID,

    X.VALOR_RECAUDADO
FROM STAGE_SRI.dbo.XLSSRI X
JOIN DWH_SRI_Recaudacion.dbo.Dim_Fecha F
	ON YEAR(X.FECHA) = F.Anio AND 
	MONTH(X.FECHA) = F.Mes AND 
    DAY(X.FECHA) = F.Dia
JOIN  DWH_SRI_Recaudacion.dbo.Dim_Impuesto I
	ON X.GRUPO_IMPUESTO = I.Grupo_Impuesto AND
	X.SUBGRUPO_IMPUESTO = I.Subgrupo_Impuesto AND
	X.IMPUESTO = I.Impuesto
JOIN  DWH_SRI_Recaudacion.dbo.Dim_Contribuyente C
	ON X.GRAN_CONTRIBUYENTE = C.Gran_Contribuyente AND
	X.CODIGO_OPERA_FAMILIA = C.Codigo_Opera_Familia AND
	X.TIPO_CONTRIBUYENTE = C.Tipo_Contribuyente
JOIN  DWH_SRI_Recaudacion.dbo.Dim_Ubicacion U
	ON X.PROVINCIA = U.Provincia