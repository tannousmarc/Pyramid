module While where

import Yoda

-- Nick's implementation of chainl
-- p is thing, op is thing -> thing -> thing, returns thing
chainl p op = p >>= rest where
  rest x = do f <- op
              y <- p
              rest (f x y)
       <|> return x

type Var = String

whitespace :: Parser ()
whitespace = () <$ (many (char ' '))

tok :: String -> Parser String
tok text = string text <* whitespace


data Aexp = Num Int
          | Var Var
          | Aexp :*: Aexp
          | Aexp :-: Aexp
          | Aexp :+: Aexp
          deriving Show

-- boolean logic is UPPERCASE
data Bexp = TRUE
          | FALSE
          | Aexp :=: Aexp
          | Aexp :<=: Aexp
          | NOT Bexp
          | Bexp :&&: Bexp
          deriving Show


-- TODO: Split into DV, DP, whatever
data Stmnt = Var ::=: Aexp
           | Skip
           | Stmnt :.: Stmnt
           | If Bexp Stmnt Stmnt
           | While Bexp Stmnt
           | Block [Stmnt] [Pexp] [Stmnt]
           | Call Proc
           deriving Show

aexp  = chainl aexp_ ((:+:) <$ tok "+")

-- _ is opposite of '
aexp_ = chainl aexp__ ((:-:) <$ tok "-")

aexp__ = chainl aexp___ ((:*:) <$ tok "*")

-- cheating by using read, similar to TB1
aexp___ = Num <$> (read <$> some (oneOf ['0' .. '9']) <* whitespace)
        <|> Var <$> var

var = (some (oneOf (['a' .. 'z'] ++ ['A' .. 'Z'])) <* whitespace)

bexp = chainl bexp_ ((:&&:) <$ tok "&&")

bexp_ =  TRUE <$ tok "true"
      <|> FALSE <$ tok "false"
      <|> (:=:) <$> aexp <* tok "=" <*> aexp
      <|> (:<=:) <$> aexp <* tok "<=" <*> aexp
      <|> NOT <$ tok "!" <*> bexp


stmnt = chainl stmnt_ ((:.:) <$ tok ";")

stmnt_ = If <$ tok "if" <*> bexp <* tok "then" <*> stmnt <* tok "else" <*> stmnt
      <|> allocation
      <|> Skip <$ tok "skip"
      <|> While <$ tok "while" <*>  bexp <* tok "do" <*> stmnt
      <|> begin
      <|> Call <$ tok "call" <*> var

type Proc = String

data Pexp = Proc Proc Stmnt
          deriving Show

procedure = Proc <$ tok "proc" <*> var <* tok "is" <*> stmnt

begin  = Block <$ tok "begin" <*> many declaration <*> many procedure <*> many stmnt <* tok "end"

allocation = (::=:) <$> var <* tok ":=" <*> aexp

declaration = tok "var" *> allocation