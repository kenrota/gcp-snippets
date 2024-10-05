use polars::prelude::*;
use rand::Rng;
use std::error::Error;

// データを生成する関数
fn generate_data(n: usize) -> Result<DataFrame, PolarsError> {
    // 乱数生成器の初期化
    let mut rng = rand::thread_rng();

    // id: 文字列
    let ids: Vec<String> = (0..n).map(|i| format!("id_{:03}", i)).collect();

    // year: 文字列（2000〜2020のランダムな年）
    let years: Vec<String> = (0..n)
        .map(|_| rng.gen_range(2000..=2020).to_string())
        .collect();

    // f1, f2, f3: 1から10の整数
    let f1: Vec<i32> = (0..n).map(|_| rng.gen_range(1..=10)).collect();
    let f2: Vec<i32> = (0..n).map(|_| rng.gen_range(1..=10)).collect();
    let f3: Vec<i32> = (0..n).map(|_| rng.gen_range(1..=10)).collect();

    // target: 0から1の小数
    let target: Vec<f64> = (0..n).map(|_| rng.random::<f64>()).collect();

    // 各列のSeriesを作成
    let id_series = Series::new("id".into(), ids);
    let year_series = Series::new("year".into(), years);
    let f1_series = Series::new("f1".into(), f1);
    let f2_series = Series::new("f2".into(), f2);
    let f3_series = Series::new("f3".into(), f3);
    let target_series = Series::new("target".into(), target);

    // DataFrameを作成
    let df = DataFrame::new(vec![
        id_series,
        year_series,
        f1_series,
        f2_series,
        f3_series,
        target_series,
    ])?;

    Ok(df)
}

fn main() -> Result<(), Box<dyn Error>> {
    // データの行数
    let n = 100;

    // データを生成
    let mut df = generate_data(n)?;

    // Parquetファイルに書き込み
    let file = std::fs::File::create("out/data.parquet")?;
    ParquetWriter::new(file)
        .with_compression(ParquetCompression::Snappy)
        .finish(&mut df)?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_data() {
        let n = 10;
        let df = generate_data(n).expect("データの生成に失敗しました");

        // データの行数を検証
        assert_eq!(df.height(), n);

        // 列名を検証
        let expected_columns = vec!["id", "year", "f1", "f2", "f3", "target"];
        assert_eq!(df.get_column_names(), expected_columns);

        // id列のデータ型を検証
        let id_series = df.column("id").unwrap();
        assert_eq!(id_series.dtype(), &DataType::String);

        // f1, f2, f3の値が1から10の範囲内かどうか検証
        for col_name in &["f1", "f2", "f3"] {
            let series = df.column(col_name).unwrap();
            let min = series.i32().unwrap().min().unwrap();
            let max = series.i32().unwrap().max().unwrap();
            assert!(min >= 1 && max <= 10, "{}の値が範囲外です", col_name);
        }

        // target列の値が0から1の範囲内かどうか検証
        let target_series = df.column("target").unwrap();
        let min = target_series.f64().unwrap().min().unwrap();
        let max = target_series.f64().unwrap().max().unwrap();
        assert!(
            min >= 0.0 && max <= 1.0,
            "targetの値が範囲外です: min={}, max={}",
            min,
            max
        );
    }
}
