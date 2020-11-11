using StaticPermutations
using Documenter

DocMeta.setdocmeta!(StaticPermutations, :DocTestSetup, :(using StaticPermutations);
                    recursive=true)

makedocs(;
    modules=[StaticPermutations],
    authors="Juan Ignacio Polanco <jipolanc@gmail.com> and contributors",
    repo="https://github.com/jipolanco/StaticPermutations.jl/blob/{commit}{path}#L{line}",
    sitename="StaticPermutations.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://jipolanco.github.io/StaticPermutations.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jipolanco/StaticPermutations.jl.git",
    forcepush=true,
)
