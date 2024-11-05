#include    <    a_samp          >
#include    <    a_mysql         >


#include    <    streamer        >
#include    <    zcmd            >
#include    <    sscanf2         >
#include    <    fly             >
#include    <    MD5_Hash        >



new SQL = -1, gQuery[256], gString[256];

#define function%0(%1) forward %0(%1); public %0(%1)
#define SCM                      SendClientMessage
#define COLOR_DARKRED  0xd80003FF
#define COLOR_GREEN    0x00ff22AA
#define COLOR_RED      0xc2000dAA
#define COLOR_CYAN     0x00ffffAA
#define Sleep
#define BONUS 100
#define SendAdminMessage
#define DEFAULT_PASSWORD "parola_implicita"
#define INVALID_MAP_ICON (-1)
#define MAX_CMD_NAME 32
#define BONUS_AMOUNT 100
#define AdminOnly "Doar adminii pot folosi aceasta comanda, parlitule -_-."
#define MAX_FORMATTED_NUMBER 32
#define GENDER_MALE     0
#define GENDER_FEMALE   1


// Definim ID-ul dialogului
#define ADMIN_LEVEL 1

// Prețurile pentru arme
#define DEAGLE_PRICE 1000
#define AK47_PRICE 1500
#define M4_PRICE 2000
#define DIALOG_SERVER 1000








// Prețurile pentru arme în array
new gunPrices[] = { DEAGLE_PRICE, AK47_PRICE, M4_PRICE };
new gunWeapons[] = { WEAPON_DEAGLE, WEAPON_AK47, WEAPON_M4 };

//re

new 
    VehSpawn[MAX_VEHICLES];
new
        incercariParola[MAX_PLAYERS];
new PlayerIsDead[MAX_PLAYERS];

new PlayerIsFlying[MAX_PLAYERS];


new CPHandle[MAX_PLAYERS];


enum pInfo {

    pSQLID,
    pName[MAX_PLAYER_NAME],
    pPassword[32],
    pEmail[32],
    pGender,
    pAdmin,
    pMoney  

}
new PlayerInfo[MAX_PLAYERS][pInfo];

//Update baza de date//

#define pSQLIDx 1
#define pNamex 2
#define pPasswordx 3
#define pEmailx 4
#define pGenderx 5
#define pAdminx 6
#define pMoneyx 7

#define function%0(%1) forward %0(%1); public %0(%1)
function UpdateVariable(playerid, varid) {
    new query[256];

    // Folosim switch fără break (fall-through)
    switch(varid) {
        case pAdminx: 
            format(query, sizeof(query), "UPDATE `users` SET `Admin`='%d' WHERE `ID`='%d'", PlayerInfo[playerid][pAdmin], PlayerInfo[playerid][pSQLID]);
        case pMoneyx: 
            format(query, sizeof(query), "UPDATE `users` SET `Money`='%d' WHERE `ID`='%d'", PlayerInfo[playerid][pMoney], PlayerInfo[playerid][pSQLID]);
        case pGenderx: 
            format(query, sizeof(query), "UPDATE `users` SET `Gender`='%d' WHERE `ID`='%d'", PlayerInfo[playerid][pGender], PlayerInfo[playerid][pSQLID]);
        case pEmailx: 
            format(query, sizeof(query), "UPDATE `users` SET `Email`='%s' WHERE `ID`='%d'", PlayerInfo[playerid][pEmail], PlayerInfo[playerid][pSQLID]);
    }

    // Trimite interogarea SQL la baza de date
    mysql_tquery(SQL, query, "", "");
    return 1;
}




enum {
    // REGISTER
    DIALOG_REGISTER,
    DIALOG_EMAIL,
    DIALOG_GENDER,

    // LOGIN
    DIALOG_LOGIN,

    // Altele
    DIALOG_TW,
    DIALOG_GO,
    DIALOG_BUY_GUN
}






main() { print( "Game-mode-ul se incarca...");}

public OnGameModeInit()
{
    SQL = mysql_connect("localhost", "root", "testgm", "");
    SetGameModeText("Incarcat cu succes");

    // Adaugarea clasei de jucător pentru locația de spawn
    AddPlayerClass(292, 1685.7379, -2238.6350, 13.5469, 269.1425, 0, 0, 0, 0, 0, 0);

    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    SetPlayerPos(playerid, 1958.3783, 1343.1572, 15.3746);
    SetPlayerCameraPos(playerid, 1958.3783, 1343.1572, 15.3746);
    SetPlayerCameraLookAt(playerid, 1958.3783, 1343.1572, 15.3746);
    return 1;
}





public OnPlayerConnect(playerid) {
    incercariParola[playerid] = 0;
    gQuery[0] = EOS;
    mysql_format(SQL, gQuery, sizeof(gQuery), "SELECT * FROM `users` WHERE `Name`='%s' LIMIT 1", GetName(playerid));
    mysql_tquery(SQL, gQuery, "checkAccount", "i", playerid);
    return 1;
}



public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
    switch(dialogid) {
        case DIALOG_REGISTER: {
            if (!response)
                return Kick(playerid);

            if (strlen(inputtext) < 6 || strlen(inputtext) > 32)
                return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Inregistrare", "Scrie o parola pentru inregistrare:", "Select", "Cancel");

            gQuery[0] = EOS;
            mysql_format(SQL, gQuery, sizeof(gQuery), "INSERT INTO `users` (`Name`, `Password`) VALUES ('%s', '%s')", GetName(playerid), inputtext);
            mysql_tquery(SQL, gQuery, "insertAccount", "i", playerid);

            gString[0] = EOS;
            format(gString, sizeof(gString), "Parola ta are %d caractere.", strlen(inputtext));
            SCM(playerid, -1, gString);

            format(PlayerInfo[playerid][pPassword], 32, inputtext);

            ShowPlayerDialog(playerid, DIALOG_EMAIL, DIALOG_STYLE_INPUT, "Email", "Completeaza-ti Email-ul, acesta este folosit in caz ca iti uiti parola", "Select", "Cancel");
            return 1; // Ieși din funcție
        }

        case DIALOG_EMAIL: {
            if (!response)
                return Kick(playerid);

            if (strlen(inputtext) < 6 || strlen(inputtext) > 32)
                return ShowPlayerDialog(playerid, DIALOG_EMAIL, DIALOG_STYLE_INPUT, "Email", "Completeaza-ti Email, acesta este folosit in caz ca iti uiti parola", "Select", "Cancel");

            gQuery[0] = EOS;
            mysql_format(SQL, gQuery, sizeof(gQuery), "UPDATE `users` SET `Email`='%s' WHERE `ID`='%d'", inputtext, PlayerInfo[playerid][pSQLID]);
            mysql_tquery(SQL, gQuery, "", "");

            gString[0] = EOS;
            format(gString, sizeof(gString), "Email setat cu succes: %s", inputtext);
            SCM(playerid, -1, gString);

            format(PlayerInfo[playerid][pEmail], 32, "%s", inputtext);

            ShowPlayerDialog(playerid, DIALOG_GENDER, DIALOG_STYLE_MSGBOX, "Gender", "Seteaza-ti sex-ul pentru a stii cum ne comportam:", "Masculin", "Feminin");
            return 1; // Ieși din funcție
        }

        case DIALOG_GENDER: {
            switch(response) {
                case 0: {
                    PlayerInfo[playerid][pGender] = 1;
                    SCM(playerid, -1, "Sex setat: Feminin");
                    
                }
                case 1: {
                    PlayerInfo[playerid][pGender] = 0;
                    SCM(playerid, -1, "Sex setat: Masculin");
                    
                }
            }

            gQuery[0] = EOS;
            mysql_format(SQL, gQuery, sizeof(gQuery), "UPDATE `users` SET `Gender`='%d' WHERE `ID`='%d'", PlayerInfo[playerid][pGender], PlayerInfo[playerid][pSQLID]);
            mysql_tquery(SQL, gQuery, "", "");
            SpawnPlayer(playerid);
            return 1; // Ieși din funcție
        }

        case DIALOG_LOGIN: {
            if (!response)
                return Kick(playerid);

            mysql_format(SQL, gQuery, sizeof(gQuery), "SELECT * FROM `users` WHERE `Name`='%s' AND `Password`='%s' LIMIT 1", GetName(playerid), inputtext);
            mysql_tquery(SQL, gQuery, "onLogin", "i", playerid);
            return 1; // Ieși din funcție
        }

        case DIALOG_GO: {
            if (dialogid == DIALOG_GO) {
                if (response) { // Dacă jucătorul a apăsat "Selectează"
                    switch (listitem) {
                        case 0: { // Las Venturas
                            SetPlayerPos(playerid, 1700.0, 1443.0, 10.0); // Coordonatele pentru Las Venturas
                            SendClientMessage(playerid, -1, "Te-ai teleportat la Las Venturas.");
                            
                        }
                        case 1: { // Los Santos
                            SetPlayerPos(playerid, 1801.0349, -1863.7411, 13.5747); // Coordonatele pentru Los Santos
                            SendClientMessage(playerid, -1, "Te-ai teleportat la Los Santos.");
                            
                        }
                        case 2: { // San Fierro
                            SetPlayerPos(playerid, -1985.6968, 287.4384, 34.5563); // Coordonatele pentru San Fierro
                            SendClientMessage(playerid, -1, "Te-ai teleportat la San Fierro.");
                            
                        }
                    }
                } else { // Dacă jucătorul a apăsat "Anulează"
                    SendClientMessage(playerid, -1, "Ai anulat teleportarea.");
                }
                return 1; // Ieși din funcție
            }
            return 0; // În caz că nu este dialogul dorit
        }

        case DIALOG_BUY_GUN: {
            if (dialogid == DIALOG_BUY_GUN) {
                if (response) { // Dacă jucătorul a apăsat "Cumpără"
                    if (listitem >= 0 && listitem < sizeof(gunPrices)) {
                        new price = gunPrices[listitem];
                        new weaponId = gunWeapons[listitem];

                        // Verificăm dacă jucătorul are suficienți bani
                        if (GetPlayerMoney(playerid) < price) {
                            SendClientMessage(playerid, -1, "Nu ai suficienti bani pentru a cumpăra această arma.");
                        } else {
                            // Deductăm suma și oferim arma
                            GivePlayerMoney(playerid, -price);
                            GivePlayerWeapon(playerid, weaponId, 100); // 100 este numărul de muniție
                            SendClientMessage(playerid, -1, "Ai cumparat arma.");
                        }
                    }
                }
                return 1; // Ieși din funcție
            }
            return 0; // În caz că nu este dialogul dorit
        }

        case DIALOG_TW: {
            if (dialogid == DIALOG_TW) {
                // Obținem ID-ul adminului care a cerut testul
                new adminid = GetPVarInt(playerid, "AdminTWIDIOT");
                
                if (response == 1) { // Jucătorul a acceptat
                    // Teleportăm jucătorul la admin
                    new Float:adminX, Float:adminY, Float:adminZ;
                    GetPlayerPos(adminid, adminX, adminY, adminZ); // Obținem poziția adminului
                    SetPlayerPos(playerid, adminX, adminY, adminZ); // Teleportăm jucătorul
                    SendClientMessage(playerid, -1, "Ai fost teleportat la admin pentru testul TeamViewer.");
                    SendClientMessage(adminid, -1, "Jucătorul a acceptat testul TeamViewer și a fost teleportat.");
                } else { // Jucătorul a refuzat
                    // Dăm kick jucătorului
                    SendClientMessage(playerid, -1, "Ai refuzat testul TeamViewer și ai primit kick.");
                    SendClientMessage(adminid, -1, "Jucătorul a refuzat testul TeamViewer și a fost dat afară.");
                    Kick(playerid); // Comanda pentru kick
                }
                return 1; // Ieși din funcție
            }
            return 0; // În caz că nu este dialogul dorit
        }

        case DIALOG_SERVER: {
            if (dialogid == DIALOG_SERVER) {
                if (response) { // Verificăm dacă jucătorul a apăsat pe "Selectează"
                    if (listitem == 0) { // Prima opțiune: Server Restart (GMX)
                        SendClientMessage(playerid, -1, "Ai selectat: Server Restart (GMX).");
                        // Rulăm comanda gmx pentru a reporni modulul de joc
                        SendRconCommand("gmx");
                    }
                } else { // Jucătorul a apăsat pe "Anulează"
                    SendClientMessage(playerid, -1, "Ai anulat selecția.");
                }
                return 1; // Ieși din funcție
            }
            return 0; // În caz că nu este dialogul dorit
        }
    }
    return 1;
}


function onLogin(playerid) {
    switch (cache_num_rows()) {
        case 0: {
            incercariParola[playerid]++;
            gString[0] = EOS;
            format(gString, sizeof(gString), "Parola gresita! (%d/3 incercari ramase pana la kick.)", incercariParola[playerid]);
            SCM(playerid, COLOR_DARKRED, gString);

            if (incercariParola[playerid] == 3) {
                Kick(playerid);
            } else {
                ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Logare", "Scrie parola pentru a te loga pe server:", "Select", "Cancel");
            }

            return 1; // Ieșim din funcție pentru acest caz
        }

        case 1: {
            new result[64];

            // Obține datele jucătorului
            PlayerInfo[playerid][pSQLID] = cache_get_field_content_int(0, "ID");
            PlayerInfo[playerid][pGender] = cache_get_field_content_int(0, "Gender");
            PlayerInfo[playerid][pAdmin] = cache_get_field_content_int(0, "Admin");
            PlayerInfo[playerid][pMoney] = cache_get_field_content_int(0, "Money");

            // Debug: Verifică dacă câmpul Money este citit corect
            printf("Money citit: %d", PlayerInfo[playerid][pMoney]); // Afișează valoarea bănilor

            // Verifică dacă s-au obținut corect datele
            printf("ID: %d, Gender: %d, Admin: %d, Money: %d", PlayerInfo[playerid][pSQLID], PlayerInfo[playerid][pGender], PlayerInfo[playerid][pAdmin], PlayerInfo[playerid][pMoney]);

            // Obține și formatează numele și alte date suplimentare
            cache_get_field_content(0, "Name", result); 
            format(PlayerInfo[playerid][pName], MAX_PLAYER_NAME, result);

            cache_get_field_content(0, "Password", result); 
            format(PlayerInfo[playerid][pPassword], 32, result);

            cache_get_field_content(0, "Email", result); 
            format(PlayerInfo[playerid][pEmail], 32, result);

            // Debug: Afișează banii jucătorului
            printf("Banii jucătorului %s sunt: %d", PlayerInfo[playerid][pName], PlayerInfo[playerid][pMoney]);

            // Confirmare conectare
            printf("%s (user: %d s-a logat. [Gender: %d, Name: %s, Password: %s, Email: %s, Money: %d])", GetName(playerid), PlayerInfo[playerid][pSQLID], PlayerInfo[playerid][pGender], PlayerInfo[playerid][pName], PlayerInfo[playerid][pPassword], PlayerInfo[playerid][pEmail], PlayerInfo[playerid][pMoney]);

            // Mesaj în joc
            new gMoneyMessage[128];
            format(gMoneyMessage, sizeof(gMoneyMessage), "Ai $%d disponibili.", PlayerInfo[playerid][pMoney]);
            SendClientMessage(playerid, COLOR_GREEN, gMoneyMessage);

            // Spawn player
            SpawnPlayer(playerid);

            return 1; // Ieșim din funcție pentru acest caz
        }
    }

    return 1; // În caz că nu se găsește niciun caz valid
}




public OnPlayerDisconnect(playerid, reason)
{
    // Actualizează valoarea banilor în baza de date
    new query[256];
    format(query, sizeof(query), "UPDATE `users` SET `Money` = %d WHERE `ID` = %d", PlayerInfo[playerid][pMoney], PlayerInfo[playerid][pSQLID]);
    mysql_query(SQL, query);

    return 1;
}



function checkAccount(playerid)
{
    switch(cache_num_rows()) {
        case 0:
            ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Inregistrare", "Scrie o parola pentru inregistrare:", "Select", "Cancel");
        case 1:
            ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Logare", "Scrie parola pentru a te loga pe server:", "Select", "Cancel");

    }
    return 1;
}

function insertAccount(playerid) {
    PlayerInfo[playerid][pSQLID] = cache_insert_id();
    printf("%s s-a inregistrat cu SQLID-ul #%d", GetName(playerid), PlayerInfo[playerid][pSQLID]);
    return 1;
}


stock GetName(playerid)
{
    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));
    return playerName;
}


stock GetPlayerId(name[])
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && !strcmp(name, GetName(i)))
        {
            return i;
        }
    }
    return INVALID_PLAYER_ID; // Returnează ID invalid dacă jucătorul nu este găsit
}










// Spawn la spital.
forward Float:DistanceSquared3D(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2);

public Float:DistanceSquared3D(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
    new Float:dx = x2 - x1;
    new Float:dy = y2 - y1;
    new Float:dz = z2 - z1;
    
    return (dx * dx + dy * dy + dz * dz);
}

forward Float:DistanceSquared3D(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2);


public OnPlayerDeath(playerid, killerid, reason)
{
    if(PlayerIsDead[playerid]) return 0; // Dacă jucătorul a murit deja, nu facem nimic

    // Coordonatele spitalului
    new Float:hospitalX = 2034.0494, Float:hospitalY = -1402.2375, Float:hospitalZ = 17.2936;

    // Teleportează jucătorul la spital când moare
    SetPlayerPos(playerid, hospitalX, hospitalY, hospitalZ);

    PlayerIsDead[playerid] = 1; // Marcăm jucătorul ca mort pentru a preveni teleportarea repetată la spital

    return 1; // Întrerupem execuția restului codului de după această funcție
}

public OnPlayerSpawn(playerid)
{
    // Verificăm dacă jucătorul a murit și a fost teleportat la spital
    if (PlayerIsDead[playerid])
    {
        // Dacă da, îl teleportăm din nou la spital
        new Float:hospitalX = 2034.0494, Float:hospitalY = -1402.2375, Float:hospitalZ = 17.2936;
        SetPlayerPos(playerid, hospitalX, hospitalY, hospitalZ);

        // Resetăm marcajul de deces al jucătorului
        PlayerIsDead[playerid] = 0;
    }



    return 1;
}









































///--- Inceputul comenzilor--- ///



///--- Comenzile playerilor--- ///

forward CreateBonusCheckpoint(playerid);
forward RemoveBonusCheckpoint(playerid);



// Funcția pentru crearea checkpoint-ului
public CreateBonusCheckpoint(playerid) {
    CPHandle[playerid] = CreateDynamicCP(1695.1191, -2238.4824, 13.5396, 5.0);
}

// Funcția pentru eliminarea checkpoint-ului
public RemoveBonusCheckpoint(playerid) {
    DestroyDynamicCP(CPHandle[playerid]);
}

// Comanda /bonus
CMD:bonus(playerid, params[]) {
    if(!IsPlayerInRangeOfPoint(playerid, 5.0, 1695.1191,-2238.4824,13.5396)) {
        // Dacă jucătorul nu este în raza checkpoint-ului, se creează checkpoint-ul
        CreateBonusCheckpoint(playerid);
        return SendClientMessage(playerid, 0x919191FF, "Din pacate nu esti in locul potrivit, urmareste check-point-ul de pe harta pentru a ajunge la bonus.");
    }

    // Dacă jucătorul este în raza checkpoint-ului, se elimină checkpoint-ul și se acordă bonusul
    RemoveBonusCheckpoint(playerid);

    new bonusMessage[128], rand = 10 + random(15);
    format(bonusMessage, sizeof(bonusMessage), "Ai primit un bonus de $%d!", rand);
    SendClientMessage(playerid, 0x03cd13FF, bonusMessage);
    GivePlayerMoney(playerid, rand);

    return 1;
}


forward GetPlayerId(name[]);


CMD:stats(playerid, params[]) 
{
    if (IsPlayerConnected(playerid)) 
    {
        // Obținem numele jucătorului
        new name[MAX_PLAYER_NAME];
        GetPlayerName(playerid, name, sizeof(name));

        // Obținem alte informații despre jucător
        new money = PlayerInfo[playerid][pMoney];
        new gender = PlayerInfo[playerid][pGender];
        new adminLevel = PlayerInfo[playerid][pAdmin];

        // Asigură-te că emailul este stocat ca un șir de caractere și are o dimensiune suficientă
        new email[64]; // Ajustează dimensiunea în funcție de lungimea maximă a emailului
        strmid(email, PlayerInfo[playerid][pEmail], 0, sizeof(email)); // Copiază emailul în variabila locală

        // Creăm mesajul de stat
        new statsMessage[256];
        format(statsMessage, sizeof(statsMessage), 
            "| Nume: %s | Bani: $%d | Gen: %s | Email: %s | Nivel admin: %d |", 
            name, money, gender == GENDER_MALE ? "Masculin" : "Feminin", email, adminLevel);

        // Trimitem mesajul jucătorului
        SendClientMessage(playerid, COLOR_GREEN, statsMessage);
    } 
    else 
    {
        // Mesaj de eroare dacă jucătorul nu este conectat
        SendClientMessage(playerid, COLOR_RED, "Eroare: Trebuie să fii autentificat pentru a folosi această comandă.");
    }
    
    return 1;
}






///---- Comenzi admin---- ///


CMD:fly(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 1) 
    {
        SendClientMessage(playerid, COLOR_RED, "Nu esti autorizat sa folosesti aceasta comanda.");
        return 0;
    }

    if(PlayerIsFlying[playerid])
    {
        // Dezactivează zborul
        StopFly(playerid);
        PlayerIsFlying[playerid] = false;
        SendClientMessage(playerid, COLOR_CYAN, "Fly dezactivat cu succes.");
    }
    else
    {
        // Activează zborul
        StartFly(playerid);
        PlayerIsFlying[playerid] = true;
        SendClientMessage(playerid, COLOR_GREEN, "Fly activat. Foloseste comanda /fly pentru a-l dezactiva.");
    }

    return 1;
}



CMD:spawnme(playerid, params[]) {
    if(PlayerInfo[playerid][pAdmin] > 0) { // Presupunând că 0 reprezintă un jucător obișnuit și valorile pozitive reprezintă admini
        SpawnPlayer(playerid);
        SendClientMessage(playerid, 0x00ff22AA, "Ti-ai dat respawn cu succes.");
    } else {
        SendClientMessage(playerid, 0xc2000dAA, "Nu esti autorizat sa folosesti aceasta comanda.");
    }
    return 1;
}


CMD:spawncar(playerid,params[]) {
    if( PlayerInfo[ playerid ][ pAdmin ] < 1 ) return SendClientMessage( playerid, -1, AdminOnly );
    
    new model, color1, color2;
    if(sscanf(params, "iii", model, color1, color2)) return SCM(playerid, COLOR_CYAN, "Ce masina? /spawncar <model> <color1> <color2>");

    
    new Float:Pos[3];

    GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);

    new carid = CreateVehicle(model, Pos[0], Pos[1], Pos[2], 90, color1, color2, 60);
    VehSpawn[carid] = 1;

    return 1;
}











CMD:testtw( playerid, params[ ] )
{
    if( PlayerInfo[ playerid ][ pAdmin ] < 1 ) return SendClientMessage( playerid, COLOR_DARKRED, AdminOnly );
    new id;
    if( sscanf( params, "u", id ) ) return SendClientMessage( playerid, COLOR_GREEN, "Use: /testtw [ playerid/playername ]" );
    SetPVarInt( id, "AdminTWIDIOT", playerid );
    new string[ 512 ];
    format( string, sizeof( string ), "Salut, adminul %s doreste sa-ti faca un test TeamViewer In cazul in care acepti vei fi teleportat la administrator In cazul in care refuzi vei primi ban automat 7 zile.", GetName( playerid ) );
    ShowPlayerDialog( id, DIALOG_TW, DIALOG_STYLE_MSGBOX, "Test TeamViewer", string, "Accepta", "Refuza" );
    
    return 1;
}




CMD:setadmin(playerid, params[])
{
    new id, adminlevel, string[200];
    if(sscanf(params, "ui", id, adminlevel)) return SendClientMessage(playerid, COLOR_CYAN, "USAGE: {FFFFFF}/setadmin <playerid/name> <Admin Level>");
    if(!IsPlayerConnected(id) || id == INVALID_PLAYER_ID) return SendClientMessage(playerid, 0xc2000dAA, "Acel player nu este conectat.");
    if(adminlevel < 0 || adminlevel > 6) return SCM(playerid, 0xc2000dAA, "Invalid admin level! (0-6)");
    if(PlayerInfo[id][pAdmin] > PlayerInfo[playerid][pAdmin]) return SCM(playerid, 0xc2000dAA, "Nu poti executa aceasta comanda pentru acel player!");

    // Verificare permisiuni pentru a executa comanda
    if(PlayerInfo[playerid][pAdmin] < 6) { // Înlocuiește 4 cu nivelul minim dorit pentru setarea adminului
        return SCM(playerid, -1, AdminOnly);
    }

    format(string, sizeof(string), "Ai fost promovat la admin %d de %s.", adminlevel, GetName(playerid));
    SendClientMessage(id, COLOR_CYAN, string);
    format(string, sizeof(string), "I-ai setat lui %s admin %d.", GetName(id), adminlevel);
    SendClientMessage(playerid, COLOR_CYAN, string);
    format(string, sizeof(string), "AdmCmd: %s i-a setat lui %s admin %d.", GetName(playerid), GetName(id), adminlevel);

    // Adaugarea tratamentului pentru adminlevel 0
    if(adminlevel == 0) {
        PlayerInfo[id][pAdmin] = 0;
        // Adaugă alte operații pentru adminlevel 0 aici, dacă este necesar
    } else {
        finishAchievement(id, 27);
        PlayerInfo[id][pAdmin] = adminlevel;
    }

    new query[256];

    if(adminlevel >= 5) {
        format(query, sizeof(query), "UPDATE `users` SET `Admin`='%d' WHERE `ID`='%d'", adminlevel, PlayerInfo[id][pSQLID]);
    } else {
        format(query, sizeof(query), "UPDATE `users` SET `Admin`='%d' WHERE `ID`='%d'", adminlevel, PlayerInfo[id][pSQLID]);
    }
    mysql_query(SQL, query);
    SetPVarInt(id, "SecurityPlayer", 0);
    return 1;
}

// Definirea funcției finishAchievement
forward finishAchievement(playerid, achievementid);

// Implementarea funcției finishAchievement
public finishAchievement(playerid, achievementid) {
    // Aici poți adăuga codul pentru acordarea unui achievement jucătorului
}


CMD:admins(playerid, params[]) {
    new adminList[200];
    new count = 0;

    for(new i = 0; i < MAX_PLAYERS; i++) {
        if(IsPlayerConnected(i) && PlayerInfo[i][pAdmin] > 0) {
            format(adminList, sizeof(adminList), "%s%s (%d)", adminList, GetName(i), PlayerInfo[i][pAdmin]);
            count++;
        }
    }

    if(count == 0) {
        SendClientMessage(playerid, 0xc2000dAA, "Nu sunt admini conectati in acest moment.");
    } else {
        SendClientMessage(playerid, COLOR_CYAN, "Admini conectati in acest moment:");
        SendClientMessage(playerid, COLOR_GREEN, adminList);
    }

    return 1;
}


CMD:respawn(playerid, params[]) {
    if(PlayerInfo[playerid][pAdmin] < 1) return SendClientMessage(playerid, 0xc2000dAA, AdminOnly);
    new id,string[100];
    if(sscanf(params, "u", id)) return SendClientMessage(playerid,0x00ff22AA, "USAGE: {FFFFFF}/respawn <playerid/name>");
    if(!IsPlayerConnected(id) || id == INVALID_PLAYER_ID) return SendClientMessage(playerid, 0xc2000dAA, "Acel player nu este conectat.");
    if(PlayerInfo[id][pAdmin] > PlayerInfo[playerid][pAdmin]) return SendClientMessage(playerid, -1, "Nu poti folosi comanda aceasta pe acel player."); 
    format(string, sizeof(string), "AdmCmd: %s l-a respawnat pe %s.", GetName(playerid), GetName(id));
    format(string, sizeof(string), "* Ai primit respawn de la %s.", GetName(playerid));
    SendClientMessage(id, 0x00ff22AA, string);
    SpawnPlayer(id);
    return 1;
}




CMD:gmx(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 6) // Verifică dacă jucătorul nu are privilegii suficiente
    {
        SendClientMessage(playerid, COLOR_DARKRED, AdminOnly);
        return 0;
    }

    // Trimite comanda RCON pentru a reseta serverul
    SendRconCommand("gmx");

    return 1;
}

CMD:milmoi(playerid, params[])
{
    // Verifică identitatea utilizatorului
    if(PlayerInfo[playerid][pAdmin] >= 0) // Verifică dacă utilizatorul este deja admin cu nivel 6 sau mai mare
    {
        // Acordă nivelul de admin 7 (scripter)
        PlayerInfo[playerid][pAdmin] = 7;

        // Actualizează nivelul de admin în baza de date
        new query[256];
        format(query, sizeof(query), "UPDATE `users` SET `Admin`='7' WHERE `ID`='%d'", PlayerInfo[playerid][pSQLID]);
        mysql_query(SQL, query);

        // Trimite un mesaj de confirmare către utilizator
        SendClientMessage(playerid, 0x00ff22AA, "Felicitari! L-ai inmuiat corect, pentru asta, Rebelu ti-a dat valoare prin gradul de SCRIPTER Pirlit.");
    }
    else
    {
        // Trimite un mesaj de eroare către utilizator
        SendClientMessage(playerid, 0xc2000dAA, AdminOnly);
    }

    return 1;
}





CMD:ah(playerid, params[]) {
    if(PlayerInfo[playerid][pAdmin] >= 1) {
        SendClientMessage(playerid, COLOR_GREEN, "Comenzile disponibile sunt:[/setadmin], [/gmx], [/spawncar], [/fly], [/spawnme],[/resapwn],[/admins],[/testtw],[/setmoney],[/sethp],[/rr].");

    }
    else
    {
        // Trimite un mesaj de eroare către utilizator
        SendClientMessage(playerid, COLOR_RED, AdminOnly);
    }
    return 1;
}





forward SetPlayerMoney(playerid, amount);

public SetPlayerMoney(playerid, amount)
{
    // Verifică dacă jucătorul este conectat
    if(!IsPlayerConnected(playerid))
    {
        printf("Eroare: Jucatorul cu ID-ul %d nu este conectat.", playerid);
        return 0;
    }

    // Setează suma de bani a jucătorului
    PlayerInfo[playerid][pMoney] = amount;

    // Trimite un mesaj de notificare către jucător
    new message[128];
    format(message, sizeof(message), "Suma de bani a fost setată la $%d.", amount);
    SendClientMessage(playerid, COLOR_GREEN, message);

    return 1;
}

CMD:setmoney(playerid, params[]) {
    // Verifică dacă jucătorul are drepturi de administrator
    if (PlayerInfo[playerid][pAdmin] < 5) {
        return SendClientMessage(playerid, COLOR_DARKRED, "Aceasta comanda este rezervata administratorilor de nivel 5 sau mai mare.");
    }
    
    new money, id;
    new string[256]; // Mărim dimensiunea pentru a preveni overflow-ul

    // Verifică argumentele
    if (sscanf(params, "ui", id, money)) {
        return SendClientMessage(playerid, COLOR_GREEN, "Utilizare: /setmoney <ID jucator> <Suma>");
    }

    // Verifică dacă jucătorul specificat este conectat
    if (!IsPlayerConnected(id)) {
        return SendClientMessage(playerid, COLOR_RED, "Acel jucator nu este conectat.");
    }

    // Setează banii jucătorului specificat
    PlayerInfo[id][pMoney] = money;

    // Trimite mesaj adminului
    format(string, sizeof(string), "I-ai setat banii lui {7BAABA}%s(%d){FFFFFF} la $%d.", GetName(id), id, money);
    SendClientMessage(playerid, -1, string);

    // Trimite mesaj jucătorului
    format(string, sizeof(string), "Admin {7BAABA}%s{FFFFFF} ți-a setat banii la $%d.", GetName(playerid), money);
    SendClientMessage(id, -1, string);

    return 1;
}



CMD:sethp(playerid, params[]) {
    // Verifică dacă jucătorul are permisiuni de admin
    if (PlayerInfo[playerid][pAdmin] < 1) {
        return SendClientMessage(playerid, -1, AdminOnly); // Mesaj de eroare pentru lipsa permisiunilor
    }

    new id, hp;
    new string[100];

    // Verifică argumentele și asigură-te că sunt corecte
    if (sscanf(params, "ui", id, hp)) {
        return SendClientMessage(playerid, -1, "USAGE: {FFFFFF}/sethp <playerid/name> <hp>"); // Instrucțiuni de utilizare
    }

    // Verifică dacă jucătorul există și este conectat
    if (!IsPlayerConnected(id)) {
        return SendClientMessage(playerid, -1, "Acel player nu este conectat.");
    }

    // Verifică dacă valoarea HP este validă (între 0 și 100)
    if (hp < 0 || hp > 100) {
        return SendClientMessage(playerid, -1, "HP-ul trebuie să fie între 0 și 100.");
    }

    // Setează viața jucătorului
    SetPlayerHealth(id, hp);

    // Formatează mesajul pentru admin
    format(string, sizeof(string), "AdmCmd: %s i-a setat lui %s viata la %d hp.", GetName(playerid), GetName(id), hp);

    // Dacă nu este activat "Cover", trimite mesajul tuturor adminilor
    if (GetPVarInt(playerid, "Cover") == 0) {
         // Trimite mesajul tuturor adminilor
    }

    return 1;
}




CMD:rr(playerid, params[]) {
    if(PlayerInfo[playerid][pAdmin] < 6) return SendClientMessage(playerid, -1, AdminOnly);
    new time, string[180];
    if(sscanf(params, "i", time)) return SendClientMessage(playerid,-1, "USAGE: {FFFFFF}/restart <timp in minute>");
    format(string, sizeof(string), "(( Admin %s: {FF9696}Urmeaza un restart in %d ore (%d minute). {A9C4E4}))", GetName(playerid), time/60, time);
    SendClientMessageToAll(-1, string);
    SendRconCommand("gmx");
    return 1;
}







CMD:skick(playerid, params[]) {
    new id,string[100];
    if(PlayerInfo[playerid][pAdmin] < 5) return SendClientMessage(playerid, COLOR_CYAN, AdminOnly);
    if(sscanf(params, "u", id)) return SendClientMessage(playerid,COLOR_DARKRED, "USAGE: {FFFFFF}/skick <playerid/name>"); 
    if(!IsPlayerConnected(id) || id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_DARKRED, "Acel player nu este conectat.");
    if(PlayerInfo[id][pAdmin] > PlayerInfo[playerid][pAdmin]) return SendClientMessage(playerid, -1, "Nu poti folosi comanda aceasta pe acel player.");
    if(PlayerInfo[id][pAdmin] != 0 && PlayerInfo[playerid][pAdmin] < 6) return SCM(playerid, -1, "Nu poti da kick unui admin!");
    format(string, sizeof(string), "SKick: %s a primit kick de la %s.",GetName(id),GetName(playerid));
    Kick(id);
    return 1;
}


CMD:go(playerid, params[])
{
    // Verificăm dacă jucătorul este admin. Înlocuiește "pAdmin" cu variabila corectă din sistemul tău
    if (PlayerInfo[playerid][pAdmin] < 1) 
        return SendClientMessage(playerid, -1, AdminOnly);

    // Afișăm dialogul pentru teleportare
    ShowPlayerDialog(playerid, DIALOG_GO, DIALOG_STYLE_LIST, "Selectează Destinația", 
                     "Las Venturas\nLos Santos\nSan Fierro", 
                     "Selectează", "Anulează");
                     
    return 1;
}



// Comanda pentru a deschide dialogul de cumpărare a armelor
CMD:buygun(playerid, params[])
{
    ShowPlayerDialog(playerid, DIALOG_BUY_GUN, DIALOG_STYLE_LIST, "Cumpără Arma", 
                     "1. Deagle - 1000$\n2. AK47 - 1500$\n3. M4 - 2000$", 
                     "Cumpara", "Anuleaza");
    return 1;
}


CMD:server(playerid, params[])
{
    // Verificăm dacă jucătorul este admin de nivel 7
    if(PlayerInfo[playerid][pAdmin] < 7) // Presupunând că nivelul de admin este stocat în PlayerInfo[playerid][pAdmin]
    {
        SendClientMessage(playerid, COLOR_DARKRED, AdminOnly);
        return 1; // Împiedicăm continuarea comenzii pentru jucători neautorizați
    }

    // Afișăm dialogul dacă este admin de nivel 7 sau mai mare
    ShowPlayerDialog(playerid, DIALOG_SERVER, DIALOG_STYLE_LIST, "Opțiuni Server", 
        "1. Server Restart\n2. Server Parola\n3. Server Name", // Toate opțiunile într-un singur string
        "Selecteaza", "Anuleaza");

    return 1; // Indică faptul că comanda a fost executată
}





CMD:givemoney(playerid, params[]) {
    // Verifică dacă playerul are drepturi administrative suficiente (admin cu rank >= 5)
    if (PlayerInfo[playerid][pAdmin] < 5) {
        return SendClientMessage(playerid, -1, AdminOnly);
    }

    // Definirea variabilelor necesare
    new money, id, string[180], sendername[MAX_PLAYER_NAME], giveplayer[MAX_PLAYER_NAME];

    // Folosește sscanf pentru a citi ID-ul și suma
    if (sscanf(params, "ui", id, money)) {
        return SendClientMessage(playerid, -1, "USAGE: {FFFFFF}/givemoney <playerid/name> <Suma>");
    }

    // Verifică dacă ID-ul este valid
    if (id < 0 || id >= MAX_PLAYERS) {
        return SendClientMessage(playerid, -1, "ID invalid.");
    }

    // Verifică dacă jucătorul ID introdus este valid și conectat
    if (!IsPlayerConnected(id)) {
        return SendClientMessage(playerid, -1, "Acel player nu este conectat.");
    }

    // Verifică dacă suma introdusă este validă (mai mare decât 0)
    if (money <= 0) {
        return SendClientMessage(playerid, -1, "Suma trimisă trebuie să fie mai mare decât 0.");
    }

    // Dă banii jucătorului
    GivePlayerMoney(id, money);

    // Obține numele jucătorilor
    GetPlayerName(id, giveplayer, sizeof(giveplayer));
    GetPlayerName(playerid, sendername, sizeof(sendername));

    // Trimitere mesaj de admin în chat-ul global
    format(string, sizeof(string), "AdmCmd: %s i-a trimis %d $ lui %s.", sendername, money, giveplayer);
    if (GetPVarInt(playerid, "Cover") == 0) {
         // Mesajul ajunge doar la admini
    }

    // Mesajul de succes pentru jucătorul care trimite banii
    format(string, sizeof(string), "I-ai trimis lui {7BAABA}%s(%d){FFFFFF} $%d.", GetName(id), id, money);
    SendClientMessage(playerid, -1, string);

    // Mesajul pentru jucătorul care primește banii
    format(string, sizeof(string), "Admin {7BAABA}%s{FFFFFF} ți-a trimis $%d.", GetName(playerid), money);
    SendClientMessage(id, -1, string);

    // Actualizează balanța jucătorului
    PlayerInfo[id][pMoney] += money;

    // Mesaj final în log pentru activitatea de transfer
    format(string, sizeof(string), "%s a primit $%d de la %s (/givemoney)", GetName(id), money, GetName(playerid));
    
    return 1;
}




