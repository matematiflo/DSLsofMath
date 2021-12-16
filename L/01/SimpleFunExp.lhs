%if False
\begin{code}
{-# LANGUAGE FlexibleInstances, PartialTypeSignatures #-}
module DSLsofMath.SimpleFunExp where
{-
import Prelude hiding (Num(..),Fractional(..), Floating(..))
import DSLsofMath.Algebra (Algebraic(..),Transcendental(..),
                           Additive(..),AddGroup(..),(-),
                           Multiplicative(..), MulGroup(..))
import DSLsofMath.SimpleFunExp ()
powTo n = (^n)
powTo' = powTo . fromIntegral
-}
import DSLsofMath.W01 (Env, evalEnv)
type REAL = Double
type ℝ = REAL
type ℤ = Int
\end{code}
%endif

\section{Types of functions, expressions and operators}
\label{sec:functions-and-scoping}
\paragraph{Examples of types in mathematics}

Simple types are sometimes mentioned explicitly in mathematical texts:
%
\begin{itemize}
\item \(x ∈ ℝ\)
\item \(\sqrt{\phantom{x}} : ℝ_{≥0} → ℝ_{≥0}\)
\item \((\_)² : ℝ → ℝ\) or, alternatively but \emph{not} equivalently
\item \((\_)² : ℝ → ℝ_{≥0}\)
\end{itemize}
%
However the types of \addtoindex{big operator}s (sums, limits,
integrals, etc.) are usually not given explicitly.
%
In fact, it may not be clear at first sight that the summing operator
($\sum$) should be assigned a type at all!
%
Yet this is exactly what we will set out to do, dealing with a
dangerous pitfall of mathematical notation
(\cref{sec:scoping-pitfall}).
%
However, to be able to do so convincingly we shall first clarify the
relationship between functions and expressions.

\subsection{Expressions and functions of one variable}
\label{sec:expressions-of-one-var}
Consider the following examples of function definitions:
\begin{itemize}
\item $f(x) = x - 1$
\item $g(x) = 2*x^2 + 3$
\item $h(y) = 2*y^2 + 3$
\end{itemize}

As the reader may guess by now, we can assign to |f|, |g|, |h| the
type |ℝ -> ℝ|.
%
Other choices could work, such as |ℤ -> ℤ|, etc., but for sure, they
are functions.
%
Additionally, the name of the variable appears to play no role in the
meaning of the functions, and we can say, for example, |g = h|.

Consider now the three expressions:
\begin{itemize}
\item |e1 = x - 1|
\item |e2 = 2*{-"x^2"-} + 3|
\item |e3 = 2*{-"y^2"-} + 3|
\end{itemize}
%
These are all expressions of one (free) variable.
%
We could say that their type is ℝ --- assuming that the free variable
also has type ℝ.
%
%format =?= = "\mathbin{\stackrel{?}{=}}"
Furthermore, it is less clear now if |e2 = 2*x + 3 =?= 2*y + 3 = e3|.
%
In general one cannot simply change a variable name to another without
making sure that:
%
1.~the renaming is applied everywhere uniformly and
%
2.~the new variable name is not used for another purpose in the same
scope (otherwise one informally says that there is a ``name clash'').

\index{DSL!expr. of one variable}%
%
To clarify this situation, we will now formalise expressions of one
variables as a DSL.
%
For simplicity we will focus on arithmetic expressions only.
%
Therefore we have constructors for addition, multiplication and
constants, as in \cref{sec:complex-arithmetic}.
%
Additionally, we have the all-important constructor for variables,
which we will call |X| here.
%
We can implement all this in a datatype as follows:

\subsubsection{Deep embedding}
\label{sec:FunExp}
\index{deep embedding}%
\index{FunExp@@|FunExp| (type)}%
\begin{code}
data FunExp  =  Const REAL
             |  X
             |  FunExp  :+:  FunExp
             |  FunExp  :*:  FunExp
\end{code}
%             |  Exp FunExp

We could encode our examples as follows:
\begin{itemize}
\item |e1 = X :+: Const (-1)|
\item |e2 = Const 2 :*: (X :*: X)  :+: Const 3|
\end{itemize}
We no longer have a third example: in this type we can only
ever represent one variable, as |X|, and thus we skip the last
example, equal to the second.

We can now evaluate the values of these expressions.
%
The meaning of operators and constants is as in
\cref{sec:complex-arithmetic}.
%
But, to be able to evaluate |X|, the variable, we need its value ---
and we simply take it as a parameter.
%
\index{eval@@|eval : Syn -> Sem|}%
%
\begin{code}
eval  ::  FunExp         ->  REAL  -> REAL
eval      (Const alpha)      x     = alpha
eval      X                  x     = x
eval      (e1 :+: e2)        x     = eval e1 x  +  eval e2 x
eval      (e1 :*: e2)        x     = eval e1 x  *  eval e2 x
\end{code}

However, we can make an equivalent interpretation of the above type as
\begin{spec}
eval  ::  FunExp         ->  (REAL  -> REAL)
\end{spec}
That is, |FunExp| can be interpreted as a function!
%
This is perhaps surprising, but the reason is that we used a fixed
Haskell symbol (constructor) for the variable.
%
There is only a single variable available in the syntax of |FunExp|,
and thus such expressions are really equivalent to functions of a
single argument.

\subsubsection{Shallow embedding}
\label{sec:funexp-shallow}
\index{shallow embedding}%
Thus the above was a deep embedding for functions of a single
variable.
%
A shallow embedding would be using functions as the representation,
say:

\begin{code}
type FunExpS = REAL -> REAL
\end{code}

\label{sec:funAdd}
Then we can define the operators directly on functions, as follows:
%
\begin{spec}
funConst alpha   = \x -> alpha               -- thus |funConst = const|
funX             = \x -> x                   -- and |funX = id|
funAdd  f g      = \x -> f x  +  g x         {-" "-}
funMul  f g      = \x -> f x  *  g x
\end{spec}
%
Again, we have two possible intuitive readings of the above
equations.
%
The first reading, as expressions of a single variable, is that
%
a constant |alpha| is interpreted as a constant function;
%
the variable (|X|) is interpreted as the identity function;
%
the sum of two expressions is interpreted as the sum of the evaluation
of the operands, etc.

The second reading is that we can define an arithmetic structure
(|*|,|+|, etc.) on functions, by lifting the operators to work
pointwise (as we did in \cref{def:pointwise}).

To wrap it up, if we're so inclined, we can re-define the evaluator of
the deep-embedding using the operators of the shallow embedding:
\begin{spec}
eval  ::  FunExp         ->  (REAL -> REAL)
eval      (Const alpha)  =   funConst alpha
eval      X              =   funX
eval      (e1 :+: e2)    =   funAdd  (eval e1)  (eval e2)
eval      (e1 :*: e2)    =   funMul  (eval e1)  (eval e2)
\end{spec}

Representing expressions of one variable as functions (of one
argument) is a recurring technique in this \course{}.
%
To start off, we can use it to assign types to big operators.

\subsection{Scoping and typing big operators}
\label{sec:big-operators}
Consider the mathematical expression
%
\[
  \sum_{i=1}^n {i^2}
\]
%
To be able to see which type is appropriate for $\sum$, we have to
consider the type of the summand ($i^2$ in the example) first.
%
As you may have guessed, it is an expression of one variable
($i$).
%
You may object: but surely the body of the summation operator can use
other variables!
%
You'd be entirely correct.
%
However, \emph{from the point of view of the summation}, it is as if
such other variables were constant.
%
Accepting this assertion as a fact until we can show a more
complicated example, we can now assign a type to the summation
operator.
%
For simplicity, we will be using the shallow embedding; thus the
operand can be typed as, say, $ℤ → ℝ$.
%
The other arguments will be the lower and upper limits of the sum ($1$
and $n$ in our example).
%
The variable name, $i$ shall not be represented as an argument:
%
indeed, the variable name is \emph{fixed by the representation of
  functions}.
%
There is no choice to make at the point of summation.
%
Thus, we write:

\begin{code}
summation :: ℤ -> ℤ -> (ℤ -> ℝ) -> ℝ
\end{code}
Conveniently, we can even provide a simple implementation:
\begin{code}
summation low high f = sum [f i | i <- [low..high]]
\end{code}
and use it for our example as follows:
\begin{spec}
sumOfSquares n = summation 1 n (powTo 2)
\end{spec}
%
Equivalently, we can use a \addtoindex{lambda expression} for the
summand, to give a name to the summation variable:
%
\begin{spec}
sumOfSquares n = summation 1 n (\i -> i `powTo` 2)
\end{spec}
(Recall the syntax for lambda expressions from
\cref{sec:lambda-expression}.)

%TODO: perhaps mention types: skipped here because of |ℤ|, |ℝ| mismatch.

As another example, let us represent the following nested sum
\[
  \sum_{i=1}^m \sum_{j=1}^n {i^2 + j^2}
\]
using the shallow embedding of summation.
%
This representation can be written simply as follows:
\begin{spec}
exampleSum m n = summation 1 m (\i -> summation 1 n (\j -> i^2 + j^2))
\end{spec}
Aren't we cheating though?
%
Surely we said that only one variable could occur in the summand, but
we see both |i| and |j|?
%
Well, we are not cheating as long as we use the
\emph{\addtoindex{shallow embedding}} for functions of one variable.
%
Doing so allows us to:
%
1.~use lambda notation to bind (and name) the variable name of the
summation however we wish (in this case |i| and |j|) and
%
2.~freely use any Haskell function of type |ℤ → ℝ| as the summand.
%
In particular, this function can be any lambda-expression returning
|ℝ|, and this expression can include summation itself.
%
This freedom is an advantage of shallow embeddings: if we were to use
the deep embedding, then we would need much more machinery to ensure
that we can represent summation within the deep embedding.
%
In particular we need a way to embed variable binding itself.
%
And we shall not be opening this can of worms just yet, even though we
take a glimpse in \cref{sec:multiple-variables}.

Sticking conveniently to the shallow embedding, we can apply the same
kind of reasoning to other big operators, and obtain the following
typings:
%
\begin{itemize}
\item |lim : (ℕ → ℝ) → ℝ| for the mathematical expression
  %
  \(\lim_{n → ∞} \{a_n\}\)
\index{limit (of sequence)}.%
\item \(\frac d {dt} : (ℝ → ℝ) → (ℝ → ℝ)\)

  Note that there are many notations for derivatives.
  %
  Instead of \(\frac d {dt} f\) one sees also \(df/dt\), or \(f'\) or
  even \(\dot{f}\) if the varable is time (\(t\)).
  %
  Below we'll use preferrably the |D f| notation.
  %
  \index{derivative (|D|)}%
\end{itemize}

In sum, the chief difficulty to overcome when assigning types for
mathematical operators is that they often introduce (bind) variable
names.
%
To take another example from the above, $\lim_{n → ∞}$ binds $n$ in
$a_n$.
%
In this book our stance is to make this binding clear by letting the
body of the limit ($a_n$ in the example) be a function.
%
Thus we use the type $ℕ → ℝ$ for the body.
%
Therefore the limit operator is a \addtoindex{higher-order function}.
%
A similar line of reasoning justifies the types of derivatives.
%
We return to derivatives in Chapter~\ref{sec:types}.
%study in detail how these play out first.

\subsection{Detour: expressions of several variables}
\label{sec:multiple-variables}

In first reading this section can be skipped, however it is natural to
to extend the study of expressions from single variables to multiple
variables.

\paragraph{The data type of expressions of multiple variables}
\label{sec:ArithExp}
Let us define the following type, describing a deep embedding for
simple arithmetic expressions.
%
Compared to single variable expressions, we add one argument for
variables, giving the \emph{name} of the variable.
%
Here we use a string, so we have an infinite supply of variables.
%
\index{DSL!expr. of several variables}%
%
\begin{code}
data MVExp = Va String | Ad MVExp MVExp | Di MVExp MVExp
\end{code}
where the last constructor |Di| is intended for division (for a change).

% The above declaration introduces:
% \begin{itemize}
% \item a new type |MVExp| for multi-variable arithmetic expressions,
% \item a constructor |Va :: String -> MVExp| for variables,
% \item a constructor |Ad :: MVExp -> MVExp -> MVExp| for addition, and
% \item a constructor |Mu :: MVExp -> MVExp -> MVExp| for multiplication.
% \end{itemize}
%
Example expressions include |v = Va "v"|, |e1 = Ad v v|, and |e2 = Di e1 e1|.

%if False

\begin{code}
v   = Va  "v"
e1  = Ad  v   v
e2  = Di  e1  e1
\end{code}

%endif % False

% \pj{Add some text in an earlier chapter about |:+| colon-operators, parameterised datatypes, more than one defintion variant in one file, etc. }
% If you want a constructor to be used as an infix operator you need to use
% symbol characters and start with a colon:
%
% \begin{spec}
% data MVExp' = V' String | MVExp' :+ MVExp' | MVExp' :* MVExp'
% \end{spec}
%
% Example values are then |y = V' "y"|, |e1 = y :+ y| and |e2 = x :* e1|.
%
% Finally, you can add one or more type parameters to make a whole
% family of datatypes in one go:
%
% \begin{code}
% data MVExp' v = V' v | MVExp' v :+ MVExp' v | MVExp' v :* MVExp' v
% \end{code}
% %
% The purpose of the parameter |v| here is to enable a free choice of
% type for the variables (be it |String| or |Int| or something else).
%
% The careful reader will note that the same Haskell module cannot
% contain both these definitions of |MVExp'|.
% %
% %
% This is because the name of the type and the names of the constructors
% are clashing.
% %
% The typical ways around this are either to define the types in different
% modules, or rename one of them (often by adding primes as in |MVExp'|).
% %
% In this \course{} we often take the liberty of presenting more than one
% version of a datatype without changing the names, to avoid multiple
% modules or too many primed names.

Together with a datatype for the syntax of arithmetic expressions we
want to define an evaluator of the expressions.

In the evaluator for |MVExp| we take this idea one step further: given an
environment |env| and the syntax of an arithmetic expression |e| we
compute the value of that expression.
%
Because the semantics of |env| is a partial function (modelled as a
total function of type |String -> Maybe QQ|), the semantics of
|MVExp| is a partial function too, of type |Env String QQ ->
Maybe QQ|.
%
%**TODO explain more for those not used to Haskell
\begin{code}
type QQ = Rational
evalMVExp :: MVExp -> Env String QQ -> Maybe QQ
evalMVExp e env = eval e
  where  
    eval  (Va  x)       =  evalEnv env x
    eval  (Ad  e1  e2)  =  mayAdd  (eval e1)  (eval e2)
    eval  (Di  e1  e2)  =  mayDiv  (eval e1)  (eval e2)

mayAdd :: Maybe QQ -> Maybe QQ -> Maybe QQ
mayAdd  (Just a)  (Just b)  =  Just (a+b)
mayAdd  _         _         =  Nothing

mayDiv :: Maybe QQ -> Maybe QQ -> Maybe QQ
mayDiv  (Just a)  (Just 0)  =  Nothing
mayDiv  (Just a)  (Just b)  =  Just (a/b)
mayDiv  _         _         =  Nothing
\end{code}
%
Note that there are two sources of |Nothing| in the evaluator:
undefined variables, and (avoiding) division by zero.

% The corresponding code for |MVExp'| is more general and you don't need to
% understand it at this stage, but it is left here as an example for
% those with a stronger Haskell background.\jp{Actually the MVExp/MVExp'
%   generalisation has nothing to do with the change in code.}
% %
% \begin{code}
% evalMVExp' ::  (Eq v, Additive sem, Multiplicative sem) =>
%             (Env v sem) -> (MVExp' v -> Maybe sem)
% evalMVExp' env (V' x)      =  evalEnv env x
% evalMVExp' env (e1 :+ e2)  =  liftM (+)   (evalMVExp' env e1)  (evalMVExp' env e2)
% evalMVExp' env (e1 :* e2)  =  liftM (*)   (evalMVExp' env e1)  (evalMVExp' env e2)
%
% liftM :: (a -> b -> c) -> (Maybe a -> Maybe b -> Maybe c)
% liftM op   (Just a)  (Just b)  =  Just (op a b)
% liftM _op  _         _         =  Nothing
% \end{code}

The approach taken above is to use a |String| to name each variable:
indeed, |Env String QQ| is like a table of several variables and their values.
%
% However, in other situations, it is better to refer to variables by
% position.
%
% For example, we can pick out any variable and make it a function of
% said variable like so:
% %
% \pj{Too abstract without explanation.}
% \begin{code}
% fun1 :: (Env k v -> r) -> Env k v -> k -> v -> r
% fun1 funMultiple env variable value = funMultiple ((variable,value):env)
% \end{code}
%
% \begin{exercise}
%   Assume a function |f| of 3 variables, named |"x"|, |"y"| and |"y"|,
%   and given the type |Env String REAL -> REAL|.
%   %
%   Turn it into a function |g| of type |REAL -> REAL -> REAL -> REAL|
%   with the same intended meaning.
% \end{exercise}

%*TODO: Perhaps add simple exercises on renaming and variable capture