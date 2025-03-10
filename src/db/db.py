import logging
import os

import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.exc import SQLAlchemyError

# logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database configuration
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", 5432),
    "database": os.getenv("DB_NAME"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
}

# CSV directory path
CSV_DIR = "data"


def clean_column_name(col):
    """Clean column names by replacing spaces and special characters"""
    return col.strip().lower().replace(" ", "_").replace("%", "percent")


def clean_data(df):
    """Clean data values and handle spaces"""
    # Trim whitespace from string columns
    str_cols = df.select_dtypes(include=["object"]).columns
    df[str_cols] = df[str_cols].apply(lambda x: x.str.strip())

    # Replace empty strings with None
    df.replace({"": None, " ": None}, inplace=True)

    return df


def create_db_connection():
    """Create database connection"""
    try:
        engine = create_engine(
            f"postgresql+psycopg2://{DB_CONFIG['user']}:{DB_CONFIG['password']}@"
            f"{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"
        )
        return engine
    except SQLAlchemyError as e:
        logger.error(f"Connection error: {e}")
        return None


def upload_csv_to_db(engine, csv_path, table_name):
    """Upload CSV data to PostgreSQL table"""
    try:
        # Read CSV with flexible whitespace handling
        df = pd.read_csv(csv_path, skipinitialspace=True, encoding="utf-8")

        # Clean column names and data
        df.columns = [clean_column_name(col) for col in df.columns]
        df = clean_data(df)

        # Map CSV columns to database columns
        if table_name == "fires":
            df = df.rename(
                columns={
                    "region": "location_id",  # Assuming region maps to location_id
                    "type": "fire_type",
                    "code": "code",
                    "latitude": "latitude",
                    "longitude": "longitude",
                    "forestry": "forestry",
                    "date_beginning": "date_beginning",
                    "date_end": "date_end",
                    "area_beginning": "area_beginning",
                    "area_total": "area_total",
                    "current_state": "current_state",
                }
            )
            # Add geometry column for PostGIS
            df["location"] = df.apply(
                lambda row: f"POINT({row['longitude']} {row['latitude']})", axis=1
            )

        # Upload to PostgreSQL
        with engine.begin() as connection:
            df.to_sql(
                name=table_name,
                con=connection,
                if_exists="append",
                index=False,
                method="multi",
            )
        logger.info(
            f"Successfully uploaded {os.path.basename(csv_path)} to {table_name}"
        )
        return True
    except Exception as e:
        logger.error(f"Error processing {csv_path}: {e}")
        return False


def main():
    engine = create_db_connection()
    if not engine:
        return

    # Map CSV files to table names (modify according to your files)
    file_table_mapping = {
        "fires_data.csv": "fires",
        "regions_data.csv": "locations",
        "fire_statistics.csv": "fire_statistics",
        "transboundary_data.csv": "transboundary",
    }

    # Process all CSV files
    for csv_file, table_name in file_table_mapping.items():
        csv_path = os.path.join(CSV_DIR, csv_file)
        if os.path.exists(csv_path):
            upload_csv_to_db(engine, csv_path, table_name)
        else:
            logger.warning(f"File not found: {csv_path}")

    # Close connection
    engine.dispose()


if __name__ == "__main__":
    main()
