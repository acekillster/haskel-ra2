module Main where

-- tipos basicos

import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)
import Data.Time (UTCTime, getCurrentTime)
import Control.Exception (IOException, catch)
import Data.Char (toLower, isSpace)
import Data.List (maximumBy)
import Data.Maybe (mapMaybe)
import Data.Ord (comparing)
import System.IO (hFlush, stdout, hSetBuffering, BufferMode(..))
import Text.Read (readMaybe)

-- tipos do sistema

data Item = Item
  { itemID :: String
  , nome :: String
  , quantidade :: Int
  , categoria :: String
  } deriving (Show, Read, Eq)

type Inventario = Map String Item

data AcaoLog
  = Add
  | Remove
  | Update
  | List
  | Report
  | History
  | Seed
  | QueryFail
  deriving (Show, Read, Eq)

data StatusLog
  = Sucesso
  | Falha String
  deriving (Show, Read, Eq)

data LogEntry = LogEntry
  { timestamp :: UTCTime
  , acao :: AcaoLog
  , detalhes :: String
  , status :: StatusLog
  } deriving (Show, Read, Eq)

type ResultadoOperacao = (Inventario, LogEntry)

arquivoInventario :: FilePath
arquivoInventario = "Inventario.dat"

arquivoAuditoria :: FilePath
arquivoAuditoria = "Auditoria.log"

-- logica pura

criarLog :: UTCTime -> AcaoLog -> String -> StatusLog -> LogEntry
criarLog t a d s = LogEntry t a d s

detalhesItem :: Item -> String
detalhesItem i =
  "itemID=" ++ itemID i ++
  ";nome=" ++ nome i ++
  ";quantidade=" ++ show (quantidade i) ++
  ";categoria=" ++ categoria i

obterCampo :: String -> String -> Maybe String
obterCampo campo texto = procurar (dividir ';' texto)
  where
    prefixo = campo ++ "="

    procurar [] = Nothing
    procurar (x:xs)
      | prefixo `prefixoDe` x = Just (drop (length prefixo) x)
      | otherwise = procurar xs

prefixoDe :: String -> String -> Bool
prefixoDe [] _ = True
prefixoDe _ [] = False
prefixoDe (a:as) (b:bs) = a == b && prefixoDe as bs

addItem :: UTCTime -> String -> String -> Int -> String -> Inventario -> Either String ResultadoOperacao
addItem t iid nom qtd cat inv
  | null iid = Left "itemid vazio"
  | qtd < 0 = Left "quantidade invalida"
  | Map.member iid inv = Left "item ja existe"
  | otherwise =
      let item = Item iid nom qtd cat
          novoInv = Map.insert iid item inv
          logOk = criarLog t Add (detalhesItem item) Sucesso
      in Right (novoInv, logOk)

removeItem :: UTCTime -> String -> Int -> Inventario -> Either String ResultadoOperacao
removeItem t iid qtd inv
  | null iid = Left "itemid vazio"
  | qtd <= 0 = Left "quantidade invalida"
  | otherwise =
      case Map.lookup iid inv of
        Nothing ->
          Left "item nao encontrado"

        Just item
          | qtd > quantidade item ->
              Left "estoque insuficiente"

          | qtd == quantidade item ->
              let novoInv = Map.delete iid inv
                  logOk = criarLog t Remove ("itemID=" ++ iid ++ ";quantidade=" ++ show qtd) Sucesso
              in Right (novoInv, logOk)

          | otherwise ->
              let itemAtualizado = item { quantidade = quantidade item - qtd }
                  novoInv = Map.insert iid itemAtualizado inv
                  logOk = criarLog t Remove ("itemID=" ++ iid ++ ";quantidade=" ++ show qtd) Sucesso
              in Right (novoInv, logOk)

updateItem :: UTCTime -> String -> String -> Int -> String -> Inventario -> Either String ResultadoOperacao
updateItem t iid nom qtd cat inv
  | null iid = Left "itemid vazio"
  | qtd < 0 = Left "quantidade invalida"
  | otherwise =
      case Map.lookup iid inv of
        Nothing ->
          Left "item nao encontrado"

        Just _ ->
          let itemAtualizado = Item iid nom qtd cat
              novoInv = Map.insert iid itemAtualizado inv
              logOk = criarLog t Update (detalhesItem itemAtualizado) Sucesso
          in Right (novoInv, logOk)

historicoPorItem :: String -> [LogEntry] -> [LogEntry]
historicoPorItem iid =
  filter (\e -> obterCampo "itemID" (detalhes e) == Just iid)

logsDeErro :: [LogEntry] -> [LogEntry]
logsDeErro = filter ehErro
  where
    ehErro e =
      case status e of
        Falha _ -> True
        _ -> False

contagemMovimentacao :: [LogEntry] -> [(String, Int)]
contagemMovimentacao logs =
  Map.toList (Map.fromListWith (+) pares)
  where
    pares =
      [ (iid, 1)
      | e <- logs
      , status e == Sucesso
      , Just iid <- [obterCampo "itemID" (detalhes e)]
      ]

itemMaisMovimentado :: [LogEntry] -> Maybe (String, Int)
itemMaisMovimentado logs =
  case contagemMovimentacao logs of
    [] -> Nothing
    xs -> Just (maximumBy (comparing snd) xs)

-- persistencia

salvarInventario :: Inventario -> IO ()
salvarInventario inv =
  writeFile arquivoInventario (show (Map.toList inv))

salvarLog :: LogEntry -> IO ()
salvarLog loge =
  appendFile arquivoAuditoria (show loge ++ "\n")

lerArquivoSeguro :: FilePath -> IO String
lerArquivoSeguro caminho =
  catch (readFile caminho) tratarErro
  where
    tratarErro :: IOException -> IO String
    tratarErro _ = return ""

carregarInventario :: IO Inventario
carregarInventario = do
  conteudo <- lerArquivoSeguro arquivoInventario
  case readMaybe conteudo :: Maybe [(String, Item)] of
    Just pares -> return (Map.fromList pares)
    Nothing -> return Map.empty

carregarLogs :: IO [LogEntry]
carregarLogs = do
  conteudo <- lerArquivoSeguro arquivoAuditoria
  let linhas = filter (not . null) (lines conteudo)
  return (mapMaybe readMaybe linhas)

-- utilidades

trim :: String -> String
trim = tirar . tirar
  where
    tirar = reverse . dropWhile isSpace

lower :: String -> String
lower = map toLower

dividir :: Char -> String -> [String]
dividir _ [] = [""]
dividir c s =
  case break (== c) s of
    (a, []) -> [a]
    (a, _:resto) -> a : dividir c resto

mostrarItem :: Item -> String
mostrarItem i =
  "[" ++ itemID i ++ "] " ++ nome i ++
  " | qtd " ++ show (quantidade i) ++
  " | cat " ++ categoria i

mostrarInventario :: Inventario -> IO ()
mostrarInventario inv
  | Map.null inv = putStrLn "inventario vazio"
  | otherwise = mapM_ (putStrLn . mostrarItem) (Map.elems inv)

mostrarLog :: LogEntry -> IO ()
mostrarLog e = do
  putStrLn $ "data " ++ show (timestamp e)
  putStrLn $ "acao " ++ show (acao e)
  putStrLn $ "detalhes " ++ detalhes e
  putStrLn $ "status " ++ case status e of
    Sucesso -> "sucesso"
    Falha msg -> "falha " ++ msg
  putStrLn "----------------------------------------"

mostrarRelatorio :: [LogEntry] -> Inventario -> IO ()
mostrarRelatorio logs inv = do
  putStrLn ""
  putStrLn "========== relatorio =========="
  putStrLn $ "itens no inventario " ++ show (Map.size inv)
  putStrLn $ "logs totais " ++ show (length logs)
  putStrLn $ "logs de erro " ++ show (length (logsDeErro logs))
  case itemMaisMovimentado logs of
    Nothing ->
      putStrLn "item mais movimentado nenhum"
    Just (iid, qtd) ->
      putStrLn $ "item mais movimentado " ++ iid ++ " com " ++ show qtd ++ " operacoes"
  putStrLn ""
  putStrLn "erros registrados"
  if null (logsDeErro logs)
    then putStrLn "nenhum erro registrado"
    else mapM_ mostrarLog (logsDeErro logs)
  putStrLn "==============================="
  putStrLn ""

mostrarHistorico :: String -> [LogEntry] -> IO ()
mostrarHistorico iid logs = do
  putStrLn ""
  putStrLn $ "historico do item " ++ iid
  let historico = historicoPorItem iid logs
  if null historico
    then putStrLn "nenhum registro encontrado"
    else mapM_ mostrarLog historico
  putStrLn ""

ajuda :: IO ()
ajuda = do
  putStrLn ""
  putStrLn "comandos"
  putStrLn "add id nome qtd categoria"
  putStrLn "remove id qtd"
  putStrLn "update id nome qtd categoria"
  putStrLn "list"
  putStrLn "report"
  putStrLn "history id"
  putStrLn "seed"
  putStrLn "help"
  putStrLn "quit"
  putStrLn ""

itensExemplo :: [Item]
itensExemplo =
  [ Item "001" "Teclado" 10 "Perifericos"
  , Item "002" "Mouse" 12 "Perifericos"
  , Item "003" "Monitor" 5 "Video"
  , Item "004" "Headset" 8 "Audio"
  , Item "005" "Cabo_HDMI" 20 "Cabos"
  , Item "006" "Notebook" 3 "Computadores"
  , Item "007" "SSD" 15 "Armazenamento"
  , Item "008" "Mousepad" 30 "Perifericos"
  , Item "009" "Webcam" 7 "Video"
  , Item "010" "Caixa_de_som" 6 "Audio"
  ]

aplicarSeed :: UTCTime -> Inventario -> (Inventario, [LogEntry])
aplicarSeed t inv =
  foldl inserir (inv, []) itensExemplo
  where
    inserir (atual, logs) item =
      case addItem t (itemID item) (nome item) (quantidade item) (categoria item) atual of
        Right (novoInv, logOk) -> (novoInv, logs ++ [logOk])
        Left _ -> (atual, logs)

registrarFalha :: UTCTime -> AcaoLog -> String -> String -> IO LogEntry
registrarFalha t a detalhes msg = do
  let loge = criarLog t a detalhes (Falha msg)
  salvarLog loge
  return loge

executarAdd :: UTCTime -> [String] -> Inventario -> [LogEntry] -> IO (Inventario, [LogEntry], Bool)
executarAdd agora [_, iid, nom, qtdTxt, cat] inv logs =
  case readMaybe qtdTxt of
    Nothing -> do
      putStrLn "quantidade invalida"
      loge <- registrarFalha agora Add
        ("itemID=" ++ iid ++ ";nome=" ++ nom ++ ";quantidade=" ++ qtdTxt ++ ";categoria=" ++ cat)
        "quantidade invalida"
      return (inv, logs ++ [loge], False)

    Just qtd ->
      case addItem agora iid nom qtd cat inv of
        Right (novoInv, logOk) -> do
          salvarInventario novoInv
          salvarLog logOk
          putStrLn "item adicionado"
          return (novoInv, logs ++ [logOk], False)

        Left erro -> do
          putStrLn ("erro " ++ erro)
          loge <- registrarFalha agora Add
            ("itemID=" ++ iid ++ ";nome=" ++ nom ++ ";quantidade=" ++ show qtd ++ ";categoria=" ++ cat)
            erro
          return (inv, logs ++ [loge], False)
executarAdd _ _ inv logs = do
  putStrLn "comando add invalido"
  return (inv, logs, False)

executarRemove :: UTCTime -> [String] -> Inventario -> [LogEntry] -> IO (Inventario, [LogEntry], Bool)
executarRemove agora [_, iid, qtdTxt] inv logs =
  case readMaybe qtdTxt of
    Nothing -> do
      putStrLn "quantidade invalida"
      loge <- registrarFalha agora Remove
        ("itemID=" ++ iid ++ ";quantidade=" ++ qtdTxt)
        "quantidade invalida"
      return (inv, logs ++ [loge], False)

    Just qtd ->
      case removeItem agora iid qtd inv of
        Right (novoInv, logOk) -> do
          salvarInventario novoInv
          salvarLog logOk
          putStrLn "item removido"
          return (novoInv, logs ++ [logOk], False)

        Left erro -> do
          putStrLn ("erro " ++ erro)
          loge <- registrarFalha agora Remove
            ("itemID=" ++ iid ++ ";quantidade=" ++ show qtd)
            erro
          return (inv, logs ++ [loge], False)
executarRemove _ _ inv logs = do
  putStrLn "comando remove invalido"
  return (inv, logs, False)

executarUpdate :: UTCTime -> [String] -> Inventario -> [LogEntry] -> IO (Inventario, [LogEntry], Bool)
executarUpdate agora [_, iid, nom, qtdTxt, cat] inv logs =
  case readMaybe qtdTxt of
    Nothing -> do
      putStrLn "quantidade invalida"
      loge <- registrarFalha agora Update
        ("itemID=" ++ iid ++ ";nome=" ++ nom ++ ";quantidade=" ++ qtdTxt ++ ";categoria=" ++ cat)
        "quantidade invalida"
      return (inv, logs ++ [loge], False)

    Just qtd ->
      case updateItem agora iid nom qtd cat inv of
        Right (novoInv, logOk) -> do
          salvarInventario novoInv
          salvarLog logOk
          putStrLn "item atualizado"
          return (novoInv, logs ++ [logOk], False)

        Left erro -> do
          putStrLn ("erro " ++ erro)
          loge <- registrarFalha agora Update
            ("itemID=" ++ iid ++ ";nome=" ++ nom ++ ";quantidade=" ++ show qtd ++ ";categoria=" ++ cat)
            erro
          return (inv, logs ++ [loge], False)
executarUpdate _ _ inv logs = do
  putStrLn "comando update invalido"
  return (inv, logs, False)

executarSeed :: UTCTime -> Inventario -> [LogEntry] -> IO (Inventario, [LogEntry], Bool)
executarSeed agora inv logs
  | not (Map.null inv) = do
      putStrLn "inventario ja possui dados entao o seed foi ignorado"
      loge <- registrarFalha agora Seed "seed" "inventario ja possui dados"
      return (inv, logs ++ [loge], False)
  | otherwise = do
      let (novoInv, logsSeed) = aplicarSeed agora inv
      salvarInventario novoInv
      mapM_ salvarLog logsSeed
      putStrLn "seed feito com 10 itens"
      return (novoInv, logs ++ logsSeed, False)

processarComando :: String -> Inventario -> [LogEntry] -> IO (Inventario, [LogEntry], Bool)
processarComando linha inv logs = do
  agora <- getCurrentTime
  let partes = words (trim linha)

  case partes of
    [] ->
      return (inv, logs, False)

    ("quit":_) ->
      return (inv, logs, True)

    ("help":_) -> do
      ajuda
      return (inv, logs, False)

    ("list":_) -> do
      putStrLn ""
      putStrLn "inventario atual"
      mostrarInventario inv
      putStrLn ""
      return (inv, logs, False)

    ("report":_) -> do
      mostrarRelatorio logs inv
      return (inv, logs, False)

    ("history":iid:_) -> do
      mostrarHistorico iid logs
      return (inv, logs, False)

    ("seed":_) ->
      executarSeed agora inv logs

    ("add":_) ->
      executarAdd agora partes inv logs

    ("remove":_) ->
      executarRemove agora partes inv logs

    ("update":_) ->
      executarUpdate agora partes inv logs

    _ -> do
      putStrLn "comando invalido"
      loge <- registrarFalha agora QueryFail ("comando=" ++ linha) "comando invalido"
      return (inv, logs ++ [loge], False)

loop :: Inventario -> [LogEntry] -> IO ()
loop inv logs = do
  putStr "\ninventario> "
  hFlush stdout
  linha <- getLine
  let texto = trim linha

  if lower texto == "quit"
    then putStrLn "encerrando"
    else do
      (novoInv, novosLogs, sair) <- processarComando texto inv logs
      if sair
        then putStrLn "encerrando"
        else loop novoInv novosLogs

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering

  putStrLn "=============================="
  putStrLn " sistema de inventario"
  putStrLn "=============================="

  inventarioInicial <- carregarInventario
  logsIniciais <- carregarLogs

  if Map.null inventarioInicial
    then putStrLn "inventario vazio na inicializacao"
    else putStrLn $ "inventario carregado com " ++ show (Map.size inventarioInicial) ++ " item(ns)"

  if null logsIniciais
    then putStrLn "log vazio na inicializacao"
    else putStrLn $ "log carregado com " ++ show (length logsIniciais) ++ " entrada(s)"

  putStrLn "digite help para ver os comandos"
  loop inventarioInicial logsIniciais