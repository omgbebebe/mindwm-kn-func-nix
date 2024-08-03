{ lib
, pkgs
, python
}:
with pkgs;

python3.pkgs.buildPythonApplication {
  pname = "mindwm-knfunc";
  version = "0.1.0";

  src = ./.;

  propagatedBuildInputs = [ python ];

  format = "pyproject";
  nativeBuildInputs = with python3.pkgs; [ setuptools ];
}
