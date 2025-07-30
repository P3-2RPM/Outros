WITH                                                                    -- Início da definição da Common Table Expression (CTE)
LETALIDADE AS                                                           -- Define uma CTE chamada LETALIDADE que será usada para filtrar ocorrências
( 
    SELECT                                                                 
        ENV.numero_ocorrencia,                                          -- Seleciona o número da ocorrência da tabela de envolvidos
        ENV.digitador_id_orgao,                                         -- Seleciona o ID do órgão que registrou a ocorrência
        ENV.natureza_ocorrencia_codigo,                                 -- Seleciona o código da natureza da ocorrência
        ENV.data_hora_fato,                                             -- Seleciona a data e hora do fato
        ENV.ind_militar_policial_servico                                -- Seleciona o indicador se o militar estava em serviço
    FROM 
        db_bisp_reds_reporting.tb_envolvido_ocorrencia ENV              -- Tabela origem dos dados de envolvidos
    WHERE 1=1                                                           -- Início das condições de filtro (1=1 é sempre verdadeiro)
        AND ENV.natureza_ocorrencia_codigo IN('B01121','B01129')        -- Filtra natureza específica (Homicídio, Lesão Corporal)
        AND ENV.id_envolvimento IN (35,36,44)                           -- Filtra apenas autores, co-autores e suspeitos
        AND ENV.ind_militar_policial IS NOT DISTINCT FROM 'M'           -- Filtra apenas militares
        AND ENV.ind_militar_policial_servico IS NOT DISTINCT FROM 'S'   -- Filtra apenas militares em serviço
        AND ENV.orgao_lotacao_policial_sigla = 'PM' 				    -- Filtra sigla do órgão policial, PM
        AND YEAR(ENV.data_hora_fato) > 2023                             -- Filtra por fatos depois de 2023
)

SELECT 
tbl_env.numero_ocorrencia, 
tbl_ocorr.data_hora_fato, 
tbl_ocorr.natureza_codigo AS natureza_ocor,
tbl_ocorr.natureza_descricao_longa AS natureza_ocor_nome,
tbl_env.natureza_ocorrencia_codigo AS natureza_env, 
tbl_env.natureza_ocorrencia_descricao AS natureza_env_nome,
tbl_env.ind_consumado, 
tbl_ocorr.natureza_consumado,
tbl_ocorr.tipo_logradouro_descricao,
tbl_ocorr.logradouro_nome, 
tbl_ocorr.logradouro2_nome,
tbl_ocorr.tipo_logradouro2_descricao, 
tbl_ocorr.descricao_endereco, 
tbl_ocorr.descricao_endereco_2,
tbl_ocorr.descricao_endereco_padrao, 
tbl_ocorr.numero_endereco, 
tbl_ocorr.descricao_complemento_endereco, 
tbl_ocorr.complemento_alfa,
tbl_ocorr.numero_complementar,
tbl_ocorr.nome_bairro, 
tbl_ocorr.numero_latitude, 
tbl_ocorr.numero_longitude,
tbl_ocorr.nome_municipio, 
'02 RPM' as RPM,
CASE 
		WHEN tbl_ocorr.codigo_municipio =311860 AND (tbl_ocorr.unidade_area_militar_nome LIKE '18 BPM%' or tbl_ocorr.unidade_area_militar_nome LIKE '%/18 BPM%') AND (tbl_ocorr.unidade_area_militar_nome not LIKE '%TM%')THEN '18 BPM'
		WHEN tbl_ocorr.codigo_municipio =310670 AND (tbl_ocorr.unidade_area_militar_nome LIKE '33 BPM%' or tbl_ocorr.unidade_area_militar_nome LIKE '%/33 BPM%') AND (tbl_ocorr.unidade_area_militar_nome not LIKE '%TM%')THEN '33 BPM'
		WHEN tbl_ocorr.codigo_municipio =311860 AND (tbl_ocorr.unidade_area_militar_nome LIKE '39 BPM%' or tbl_ocorr.unidade_area_militar_nome LIKE '%/39 BPM%') AND (tbl_ocorr.unidade_area_militar_nome not LIKE '%TM%')THEN '39 BPM'
		WHEN tbl_ocorr.codigo_municipio IN (315460) THEN '40 BPM'
		WHEN tbl_ocorr.codigo_municipio IN (310900,312980,314015,316553) THEN '48 BPM'
		WHEN tbl_ocorr.codigo_municipio = 310670 AND (tbl_ocorr.unidade_area_militar_nome LIKE '66 BPM%' or tbl_ocorr.unidade_area_militar_nome LIKE '%/66 BPM%') AND (tbl_ocorr.unidade_area_militar_nome not LIKE '%TM%')THEN '66 BPM'
		WHEN tbl_ocorr.codigo_municipio IN (312410) THEN '6 CIA PM IND'
		WHEN tbl_ocorr.codigo_municipio IN (310810,312060,312600,313010,313220,313665,314070,315040,315530,316292) THEN '7 CIA PM IND'
		ELSE 'OUTROS'
END AS UEOp,
-- SPLIT_PART (tbl_ocorr.unidade_area_militar_nome,'/', -3) AS fracao_pm,
SPLIT_PART(tbl_ocorr.unidade_area_militar_nome, '/', -3) || '/' || SPLIT_PART(tbl_ocorr.unidade_area_militar_nome, '/', -2) AS fracao_pm,
tbl_env.condicao_fisica_descricao_longa, 
tbl_env.envolvimento_descricao_longa

FROM db_bisp_reds_reporting.tb_envolvido_ocorrencia as tbl_env
INNER JOIN db_bisp_reds_reporting.tb_ocorrencia as tbl_ocorr
ON tbl_env.numero_ocorrencia = tbl_ocorr.numero_ocorrencia
LEFT JOIN LETALIDADE LET ON tbl_ocorr.numero_ocorrencia = LET.numero_ocorrencia
WHERE YEAR (tbl_env.data_hora_fato ) >= 2023
AND LET.numero_ocorrencia IS NULL  -- Exclui ocorrências presentes na CTE LETALIDADE
AND tbl_ocorr.codigo_municipio in (310670 , 310810 , 310900 , 311860 , 312060 , 312410 , 312600 , 312980 , 313010 , 313220 , 313665 , 314015 , 314070 , 315040 , 315460 , 315530 , 316292 , 316553)
AND tbl_ocorr.unidade_responsavel_registro_id_orgao in (0,1 ) -- 0 POLICIA MILITAR, 1- POLICIA CIVIL
AND tbl_ocorr.ocorrencia_uf = 'MG'
AND (
       (
         (tbl_ocorr.natureza_codigo IN ('C01159', 'B01148','C01158', 'C01157','B01121','E03015' ) -- EXTORSÃO MEDIANTE SEQUESTRO, SEQUESTRO, ROUBO, EXTORSÃO, HOMICÍDIO, DISPARO DE ARMA DE FOGO
          )
        OR 
         (tbl_ocorr.natureza_codigo = 'B01129' -- LESÃO CORPORAL
          AND tbl_env.condicao_fisica_descricao_longa IN ('GRAVES OU INCONSCIENTE', 'FATAL')
          OR tbl_ocorr.instrumento_utilizado_codigo IN ('0300') -- ARMAS DE FOGO
          )
       )
     AND tbl_env.envolvimento_codigo IN ('1300', '1399', '1301', '1302', '1303', '1304', '1305') -- códigos para vítimas
     OR
        (tbl_ocorr.natureza_codigo  IN ('E03014','E03016','E03015')  -- PORTE ILEGAL ARMA DE FOGO (PERMITIDO OU RESTRITO) E DISPARO DE ARMA DE FOGO),
         AND tbl_env.envolvimento_codigo IN ('0100') -- código para autor
         )
     )