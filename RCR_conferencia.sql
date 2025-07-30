/*--------------------------------------------------------------------------------------------------------------------------------------------
 ****************************** Conferência das Reuniões Comunitárias Rurais (RCR) na Segunda Região *****************************************

 * O script tem como objetivo conferir se as reuniões realizadas dentro da região estão dentro dos parâmetros do indicador.
 -------------------------------------------------------------------------------------------------------------------------------------------*/
WITH
PARTICIPANTES AS 
(    
SELECT
    envolvido.numero_ocorrencia,
    COUNT(DISTINCT envolvido.numero_envolvido) AS quantidade_envolvidos
FROM
    db_bisp_reds_reporting.tb_envolvido_ocorrencia AS envolvido -- Boa prática usar AS para aliases
LEFT JOIN
    db_bisp_reds_reporting.tb_ocorrencia AS OCO ON envolvido.numero_ocorrencia = OCO.numero_ocorrencia -- Cláusula ON adicionada e movida para o JOIN
WHERE
    (
        envolvido.numero_cpf_cnpj IS NOT NULL                                   -- Filtra cpf/cnpj não nulo
        OR (                                                                     -- OU alternativa para identificação
            envolvido.numero_documento_id IS NOT NULL                           -- Filtra envolvidos com algum documento de identificação não nulo
            AND envolvido.tipo_documento_codigo = '0801'                        -- E que esse documento seja do tipo específico '0801' (RG)
        )
    )
    AND OCO.codigo_municipio IN (310670, 310810, 310900, 311860, 312060, 312410, 312600, 312980, 313010, 313220, 313665, 314015, 314070, 315040, 315460, 315530, 316292, 316553)
    AND year(OCO.data_hora_fato) = 2025
    AND OCO.natureza_codigo IN ('A19000', 'A19001','A19004','A19099')     
GROUP BY
    envolvido.numero_ocorrencia 							-- GROUP BY adicionado para agrupar por ocorrência
)

SELECT 
OCO.numero_ocorrencia, 										-- Número da ocorrência
COALESCE(P.quantidade_envolvidos, 0) AS envolvidos,
CASE WHEN P.quantidade_envolvidos > 2 THEN 'SIM'
ELSE 'NAO'
END AS valido_rcr,
CASE 	
    	WHEN OCO.pais_codigo <> 1 AND OCO.ocorrencia_uf IS NULL THEN 'Outro_Pais'  	-- trata erro - ocorrencia de fora do Brasil
		WHEN OCO.ocorrencia_uf <> 'MG' THEN 'Outra_UF'		-- trata erro - ocorrencia de fora de MG
    	WHEN OCO.numero_latitude IS NULL THEN 'Invalido'	-- trata erro - ocorrencia sem latitude
        WHEN geo.situacao_codigo = 9 THEN 'Agua'			-- trata erro - ocorrencia dentro de curso d'água
       	WHEN geo.situacao_zona IS NULL THEN 'Erro_Processamento'	-- checa se restou alguma ocorrencia com erro
    	ELSE geo.situacao_zona
END AS situacao_zona,      									-- se o território é Urbano ou Rural segundo o IBGE            							
OCO.natureza_codigo,      									-- Código da natureza da ocorrência
OCO.natureza_descricao,   									-- Descrição da natureza da ocorrência
CASE 	WHEN OCO.codigo_municipio in (315460) THEN '40 BPM'
     	WHEN OCO.codigo_municipio in (310900,312980,314015,316553) THEN '48 BPM'
	WHEN OCO.codigo_municipio in (312410) THEN '6 CIA PM IND'
        WHEN OCO.codigo_municipio in (310810,312060,312600,313010,313220,313665,314070,315040,315530,316292) THEN '7 CIA PM IND'
---município com mais de uma unidade
	WHEN OCO.codigo_municipio =311860 AND (LO.unidade_area_militar_nome like '18 BPM%' or LO.unidade_area_militar_nome like '%/18 BPM%') THEN '18 BPM'
        WHEN OCO.codigo_municipio =311860 AND (LO.unidade_area_militar_nome like '39 BPM%' or LO.unidade_area_militar_nome like '%/39 BPM%') THEN '39 BPM'
        WHEN OCO.codigo_municipio =310670 AND (LO.unidade_area_militar_nome like '66 BPM%' or LO.unidade_area_militar_nome like '%/66 BPM%') THEN '66 BPM'
        WHEN OCO.codigo_municipio =310670 AND (LO.unidade_area_militar_nome like '33 BPM%' or LO.unidade_area_militar_nome like '%/33 BPM%') THEN '33 BPM'
        ELSE 'OUTROS'
END AS UEOP_2025_AREA,
LO.codigo_unidade_area,										-- Código da unidade militar da área
LO.unidade_area_militar_nome,                               -- Nome da unidade militar da área
OCO.unidade_responsavel_registro_codigo,                    -- Código da unidade que registrou a ocorrência
OCO.unidade_responsavel_registro_nome,                      -- Nome da unidade que registrou a ocorrência
SPLIT_PART(OCO.unidade_responsavel_registro_nome,'/',-1) RPM_REGISTRO, 
SPLIT_PART(OCO.unidade_responsavel_registro_nome,'/',-2) UEOP_REGISTRO, 
CAST(OCO.codigo_municipio AS INTEGER),                      -- Converte o código do município para número inteiro
OCO.nome_bairro,                                            -- Nome do bairro
CONCAT(
    SUBSTR(CAST(OCO.data_hora_fato AS STRING), 9, 2), '/',  -- Dia (posições 9-10)
    SUBSTR(CAST(OCO.data_hora_fato AS STRING), 6, 2), '/',  -- Mês (posições 6-7)
    SUBSTR(CAST(OCO.data_hora_fato AS STRING), 1, 4), ' ',  -- Ano (posições 1-4)
    SUBSTR(CAST(OCO.data_hora_fato AS STRING), 12, 8)       -- Hora (posições 12-19)
  ) AS data_hora_fato,                   					-- Converte a data/hora do fato para o padrão brasileiro
YEAR(OCO.data_hora_fato) AS ano,                           	-- Ano do fato
MONTH(OCO.data_hora_fato) AS mes,                          	-- Mês do fato
OCO.nome_tipo_relatorio,                                   	-- Tipo do relatório
OCO.digitador_sigla_orgao,                                  -- Sigla do órgão que registrou
geo.latitude_sirgas2000,									-- reprojeção da latitude de SAD69 para SIRGAS2000
geo.longitude_sirgas2000									-- reprojeção da longitude de SAD69 para SIRGAS2000
FROM db_bisp_reds_reporting.tb_ocorrencia OCO
LEFT JOIN db_bisp_reds_master.tb_local_unidade_area_pmmg LO ON OCO.id_local = LO.id_local
LEFT JOIN db_bisp_reds_master.tb_ocorrencia_setores_geodata AS geo ON OCO.numero_ocorrencia = geo.numero_ocorrencia AND OCO.ocorrencia_uf = 'MG'	-- Tabela de apoio que compara as lat/long com os setores IBGE
LEFT JOIN PARTICIPANTES P ON OCO.numero_ocorrencia = P.numero_ocorrencia		
WHERE 1 = 1         										-- Condição sempre verdadeira que facilita o desenvolvimento da query, permitindo adicionar/remover condições sem preocupação com a sintaxe
AND year(OCO.data_hora_fato) = 2025  						-- Filtra ocorrências por período específico (todo o ano de 2024 até fevereiro/2025)
AND UPPER(geo.situacao_zona) = 'RURAL' 						-- Filtra ocorrências de RC realizadas em zona rural
AND OCO.natureza_codigo IN ('A19000', 'A19001','A19004','A19099')               -- Filtra ocorrências de naturezas A19000 - Reunião Comunitária ou com entidades diversas, A19001 - Reunião com CONSEP ,A19004 -Reunião com associação de moradores ,A19099 - Reunião com outros tipos de entidades.
AND OCO.ocorrencia_uf = 'MG'                                                     -- Filtra apenas ocorrências do estado de Minas Gerais
AND OCO.digitador_sigla_orgao = 'PM'                                            -- Filtra ocorrências registradas pela Polícia Militar
AND OCO.unidade_responsavel_registro_nome NOT LIKE '%IND PE%'
AND OCO.unidade_responsavel_registro_nome NOT LIKE '%PVD%'
AND (
    OCO.unidade_responsavel_registro_nome NOT REGEXP '/[A-Za-z]'
    OR OCO.unidade_responsavel_registro_nome LIKE '%/PEL TM%'
)
AND (
    OCO.unidade_responsavel_registro_nome REGEXP '^(SG|PEL|GP)'
    OR OCO.unidade_responsavel_registro_nome REGEXP '^[^A-Za-z]'
) -- Filtra apenas unidades com responsabilidade territorial. 
AND OCO.nome_tipo_relatorio IN ('BOS', 'BOS AMPLO')         -- Filtra por tipos específicos de relatórios BOS e BOS AMPLO
AND OCO.ind_estado IN ('F','R')                             -- Filtra ocorrências com indicador de estado 'F' (Fechado) e R(Pendente de Recibo)
AND OCO.codigo_municipio IN (310670 , 310810 , 310900 , 311860 , 312060 , 312410 , 312600 , 312980 , 313010 , 313220 , 313665 , 314015 , 314070 , 315040 , 315460 , 315530 , 316292 , 316553)
order by OCO.numero_ocorrencia
