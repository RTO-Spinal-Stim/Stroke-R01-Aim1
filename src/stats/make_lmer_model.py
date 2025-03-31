import pandas as pd
import statsmodels.api as sm
import statsmodels.formula.api as smf

def make_lmer_model(df: pd.DataFrame, formula: str, random_effect_col: str) -> sm.regression:
    """Make a linear mixed effects model using statsmodels."""
    model = smf.mixedlm(formula, df, groups=df[random_effect_col])
    result = model.fit()
    return result

