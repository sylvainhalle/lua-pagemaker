\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{computer}[2025/12/09 v1.0 IEEE Spectrum look-alike class]

\DeclareOption*{%
  \PassOptionsToClass{\CurrentOption}{article}%
}
\ProcessOptions
\LoadClass[letterpaper,twoside,10pt]{article}

%% Packages
\RequirePackage{fontspec}
\RequirePackage[english]{babel}
\RequirePackage[tracking=true]{microtype}
\RequirePackage{graphicx}
\graphicspath{{images/}}
\RequirePackage[x11names]{xcolor}
\RequirePackage{fancyhdr}
\RequirePackage{flowfram}
\RequirePackage[papersize={7.88in,10.5in},top=0.75in,bottom=1in,inner=0.5in,outer=0.5in,twoside]{geometry}
\RequirePackage{tcolorbox}
\RequirePackage{xparse}
\RequirePackage{setspace}
\RequirePackage{textcase}
\RequirePackage{tikz}
\RequirePackage{everypage}
\RequirePackage{lettrine}

%% Fonts
\setmainfont[Path=./fonts/,Scale=0.85,LetterSpace=-3]{LeituraRoman1.otf}
\setsansfont[Path=./fonts/,Scale=0.85]{ABCFavoritMono-Book.otf}
\newfontfamily\txfont[Path=./fonts/,Scale=0.85,LetterSpace=-3]{LeituraRoman1.otf}
\newfontfamily\bigquote[Path=./fonts/,LetterSpace=-2]{IvarText-Bold.otf}
\newfontfamily\bignews[Path=./fonts/,LetterSpace=-4]{HelveticaNeueCyr-Light.ttf}
\newfontfamily\lettrinefont[Path=./fonts/,LetterSpace=-4,Scale=0.85]{HelveticaNeueCyr-Roman.ttf}

%% Color scheme
\definecolor{bgpage}{HTML}{f2f2f2}
\definecolor{hlred}{HTML}{f03c1e}

%% Layout
\pagecolor{bgpage}
\pretolerance=1000
\tolerance=2000
\emergencystretch=3em
\hfuzz=0.5pt

%% Spacing
\setstretch{0.95}
\setlength{\parindent}{1em}

%% Headers/footers page 1
\fancypagestyle{firststyle}
{
   \fancyhf{}
   \fancyhead[L]{\sffamily\small \MakeTextUppercase{The latest developments in technology, engineering, and science}}
   \fancyfoot[L]{\sffamily\small \textbf{\thepage} \phantom{WW} %
     \MakeTextUppercase{spectrum.ieee.org}}
   \renewcommand{\headrulewidth}{0pt} % removes horizontal header line
}

%% Headers/footers page 2
\pagestyle{fancy}
\renewcommand\headrulewidth{0pt}
\fancyhf{}
\fancyhead[R]{\sffamily\small \MakeTextUppercase{\@date}}
\fancyfoot[R]{\sffamily\small \MakeTextUppercase{\@date}\phantom{WW} %
  \MakeTextUppercase{spectrum.ieee.org}\phantom{WW} %%
  \textbf{\thepage}%
}

%% Subtitle
\newcommand{\subtitle}[1]{\def\thesubtitle{#1}}

%% Big quote
\newcommand{\printquote}[1]{%
  \setlength{\hangindent}{10pt}
  \bigquote\LARGE\bfseries\textcolor{hlred}{“#1”}
  \setlength{\hangindent}{0pt}
}

%% Title
\renewcommand{\maketitle}{
  \category{Consumer Electronics}
  \vskip -4pt
  \rule{\linewidth}{0.5pt}
  \vspace*{-0.25in}
  \setstretch{0.875}
  \begin{flushleft}
  \bigquote\fontsize{28pt}{30pt}\selectfont{\@title}~$>$
  \txfont\thesubtitle
  \vskip -10pt
  \rule{\linewidth}{0.5pt}
  \vskip -14pt
  {\sffamily\normalsize\MakeTextUppercase{by \@author}}
  
  \end{flushleft}
  \thispagestyle{firststyle}
  \framebreak
  \vskip 60pt
}

%% Category
\newcommand{\category}[1]{
\sffamily\bfseries \textcolor{hlred}{\MakeTextUppercase{#1}}
}

%% Image captions
\newcommand{\imgcaption}[1]{
\sffamily\footnotesize #1
}

%% Lettrine
\newcommand{\firstletter}[2]{\lettrine[lines=4,nindent=0pt]{\lettrinefont #1}{\lettrinefont #2}}

%% Small paragraph break
\renewcommand{\paragraph}[1]{\vskip 10pt {\noindent\lettrinefont\bfseries #1}}

%% Split page
\newcommand{\splitat}{\parfillskip=0pt

\framebreak

\parfillskip=10pt
\noindent}

%% Load layout
\directlua{dofile("layout.lua")}
\AtBeginDocument{
\input boxes
}

%% :mode=latex: