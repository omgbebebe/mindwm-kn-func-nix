{ lib
, pkgs
, python
, parliament
, mindwm-sdk-python
}:
with pkgs;

python3.pkgs.buildPythonApplication {
  pname = "mindwm-knfunc";
  version = "0.1.0";

  src = ./.;

#  propagatedBuildInputs = [ python ];
  buildInputs = [ python ];
  dependencies = [
    parliament
    mindwm-sdk-python
  ];

  pythonImportsCheck = [
    "knfunc"
  ];
  format = "pyproject";
  nativeBuildInputs = with python3.pkgs; [ setuptools ];
}
