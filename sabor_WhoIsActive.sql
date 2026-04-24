SELECT
    GETDATE() AS momento_coleta,
    r.session_id                    AS sessao_id,
    s.login_name                    AS usuario,
    s.host_name                     AS maquina,
    s.program_name                  AS aplicacao,
    DB_NAME(r.database_id)          AS banco,
    r.status                        AS status_execucao,
    r.command                       AS comando,
    r.cpu_time                      AS cpu_ms,
    r.total_elapsed_time / 1000     AS tempo_execucao_s,
    r.logical_reads                 AS leituras_logicas,
    r.reads                         AS leituras_fisicas,
    r.writes                        AS escritas,
    r.wait_type                     AS tipo_espera,
    r.wait_time                     AS tempo_espera_ms,
    r.blocking_session_id           AS bloqueado_por,
    CASE 
        WHEN r.blocking_session_id = 0 THEN 'Nao'
        ELSE 'Sim'
    END                             AS esta_bloqueado,
    SUBSTRING(t.text,
        (r.statement_start_offset/2) + 1,
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(t.text)
            ELSE r.statement_end_offset
        END - r.statement_start_offset)/2) + 1
    ) AS query_em_execucao
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s 
    ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE 
    r.session_id <> @@SPID
    AND s.is_user_process = 1
ORDER BY 
    r.logical_reads DESC;