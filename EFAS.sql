WITH 																		-- criar uma cte para buscar os militares que participaram da ocorrência
GUARNICAO AS (
    SELECT 
        IGO.numero_ocorrencia,
        GROUP_CONCAT(DISTINCT IGO.numero_matricula, ', ') AS matriculas_militares	-- coloca todos os números de polícia na mesma célula separadas por vírgula
    FROM db_bisp_reds_reporting.tb_integrante_guarnicao_ocorrencia IGO
    WHERE YEAR (IGO.data_hora_fato) = :ANO
    AND IGO.unidade_servico_nome LIKE  '%/EFAS%'							-- só trará apenas os militares lotados na EFAS
    GROUP BY IGO.numero_ocorrencia											-- será agrupado por número de ocorrência
)
SELECT 
    OCO.numero_ocorrencia,
    FROM_TIMESTAMP(OCO.data_hora_fato, 'dd/MM/yy') AS data_fato,
    MONTH (OCO.data_hora_fato) as mes_fato,
    CASE 	WHEN OCO.codigo_municipio IN (315460) THEN '40 BPM'
    		WHEN OCO.codigo_municipio IN (310900,312980,314015,316553) THEN '48 BPM'
			WHEN OCO.codigo_municipio IN (312410) THEN '6 CIA PM IND'    	
			WHEN OCO.codigo_municipio IN (310810,312060,312600,313010,313220,313665,314070,315040,315530,316292) THEN '7 CIA PM IND'		
			WHEN OCO.codigo_municipio =311860 AND (OCO.unidade_area_militar_nome LIKE '39 BPM%' or OCO.unidade_area_militar_nome LIKE '%/39 BPM%') AND (OCO.unidade_area_militar_nome not LIKE '%TM%')THEN '39 BPM'
			WHEN OCO.codigo_municipio =311860 AND (OCO.unidade_area_militar_nome LIKE '18 BPM%' or OCO.unidade_area_militar_nome LIKE '%/18 BPM%') AND (OCO.unidade_area_militar_nome not LIKE '%TM%')THEN '18 BPM'
			WHEN OCO.codigo_municipio =310670 AND (OCO.unidade_area_militar_nome LIKE '66 BPM%' or OCO.unidade_area_militar_nome LIKE '%/66 BPM%') AND (OCO.unidade_area_militar_nome not LIKE '%TM%')THEN '66 BPM'
			WHEN OCO.codigo_municipio =310670 AND (OCO.unidade_area_militar_nome LIKE '33 BPM%' or OCO.unidade_area_militar_nome LIKE '%/33 BPM%') AND (OCO.unidade_area_militar_nome not LIKE '%TM%')THEN '33 BPM'
			ELSE 'OUTROS' 
	END AS UEOP,
    OCO.unidade_area_militar_codigo,                              -- Seleciona o código da unidade militar da área
    OCO.unidade_area_militar_nome,                                -- Seleciona o nome da unidade militar da área
    OCO.unidade_responsavel_registro_codigo,                      -- Seleciona o código da unidade responsável pelo registro
    OCO.unidade_responsavel_registro_nome,                        -- Seleciona o nome da unidade responsável pelo registro
    COALESCE(G.matriculas_militares, 'SEM MILITARES EFAS') AS matriculas_militares,
    OCO.natureza_codigo,
   	OCO.natureza_descricao,
   	OCO.natureza_ind_consumado,
   	OCO.nome_bairro, 
   	OCO.nome_municipio,
	REPLACE(CAST(OCO.numero_latitude AS STRING), '.', ',') AS local_latitude_formatado,    
	REPLACE(CAST(OCO.numero_longitude AS STRING), '.', ',') AS local_longitude_formatado
FROM db_bisp_reds_reporting.tb_ocorrencia OCO
LEFT JOIN GUARNICAO G ON OCO.numero_ocorrencia = G.numero_ocorrencia
WHERE 1=1
    AND YEAR (OCO.data_hora_fato) :ANO
    AND OCO.digitador_id_orgao = 0 
--    AND OCO.natureza_codigo IN ('B01121','C01157','B01504') -- Filtra naturezas específicas (Homicídio,Roubo,Tortura,Feminicídio* )
    AND OCO.codigo_municipio IN (310670 , 310810 , 310900 , 311860 , 312060 , 312410 , 312600 , 312980 , 313010 , 313220 , 313665 , 314015 , 314070 , 315040 , 315460 , 315530 , 316292 , 316553) -- filtro municípios 2RPM
--    AND LET.numero_ocorrencia IS NULL    
ORDER BY OCO.numero_ocorrencia