import asyncio
from pysnmp.hlapi.v3arch import (
    CommunityData,
    ContextData,
    ObjectIdentity,
    ObjectType,
    SnmpEngine,
    UdpTransportTarget,
    get_cmd,
)

# OIDs Estándar y Propietarios de Ricoh
OID_TOTAL_COUNTER = "1.3.6.1.2.1.43.10.2.1.4.1.1"
OID_TONER_CURRENT = "1.3.6.1.2.1.43.11.1.1.9.1.1"
OID_TONER_MAX = "1.3.6.1.2.1.43.11.1.1.8.1.1"


async def query_snmp_oid(
    snmp_engine, ip: str, oid: str, community: str = "public"
):
    """Realiza una consulta SNMP GET asíncrona usando SNMPv2c."""
    try:
        error_indication, error_status, error_index, var_binds = await get_cmd(
            snmp_engine,
            CommunityData(community, mpModel=1),  # mpModel=1 -> SNMPv2c
            await UdpTransportTarget.create(
                (ip, 161), timeout=5, retries=2
            ),  # 5 segundos de espera
            ContextData(),
            ObjectType(ObjectIdentity(oid)),
        )

        if error_indication:
            print(f"[{ip}] Error de red / SNMP: {error_indication}")
            return None

        if error_status:
            print(f"[{ip}] Error devuelto por la impresora: {error_status.prettyPrint()}")
            return None

        for var_bind in var_binds:
            return var_bind[1]
    except Exception as e:
        print(f"[{ip}] Excepción: {e}")
        return None


async def get_ricoh_info(snmp_engine, ip: str, community: str = "public"):
    """Obtiene el contador y nivel de tóner de una impresora Ricoh."""
    # 1. Obtener Contador Total
    raw_counter = await query_snmp_oid(
        snmp_engine, ip, OID_TOTAL_COUNTER, community
    )
    total_pages = int(raw_counter) if raw_counter is not None else "Error/Offline"

    # 2. Obtener Datos de Tóner
    raw_current = await query_snmp_oid(
        snmp_engine, ip, OID_TONER_CURRENT, community
    )
    raw_max = await query_snmp_oid(snmp_engine, ip, OID_TONER_MAX, community)

    toner_status = "Desconocido"

    if raw_current is not None and raw_max is not None:
        try:
            val_current = int(raw_current)
            val_max = int(raw_max)

            if val_current == -3:
                toner_status = "OK (Suficiente)"
            elif val_current == -2:
                toner_status = "Desconocido"
            elif val_max > 0 and val_current >= 0:
                percentage = (val_current / val_max) * 100
                toner_status = f"{percentage:.1f}%"
        except ValueError:
            pass

    return {"ip": ip, "counter": total_pages, "toner": toner_status}


async def main():
    # IP de tu Ricoh MP 501
    MIS_IMPRESORAS = [
        "192.168.2.230",
    ]
    COMUNIDAD_SNMP = "public"

    snmp_engine = SnmpEngine()

    print("Iniciando escaneo de impresoras Ricoh...\n")
    print(f"{'Dirección IP':<18} | {'Contador Total':<16} | {'Nivel de Tóner':<15}")
    print("-" * 55)

    tasks = [
        get_ricoh_info(snmp_engine, ip, COMUNIDAD_SNMP) for ip in MIS_IMPRESORAS
    ]
    results = await asyncio.gather(*tasks)

    for res in results:
        print(f"{res['ip']:<18} | {str(res['counter']):<16} | {res['toner']:<15}")


if __name__ == "__main__":
    asyncio.run(main())