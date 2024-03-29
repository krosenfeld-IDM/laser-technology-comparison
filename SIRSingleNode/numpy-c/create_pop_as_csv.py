import sqlite3
import csv
import settings
from sir_sql import initialize_database

def create_pop_csv():
    conn = sqlite3.connect(":memory:")  # Use in-memory database for simplicity
    initialize_database( conn )

    print( f"Writing population file out out to csv: {settings.pop_file_out}." )
    cursor = conn.cursor()
    get_all_query = "SELECT * FROM agents"
    cursor.execute( get_all_query )
    rows = cursor.fetchall()

    conn.close()

    with open( settings.pop_file_out, "w", newline='' ) as csvfile:
        csv_writer = csv.writer( csvfile )
        csv_writer.writerow( ['id', 'node', 'age', 'infected', 'infection_timer', 'incubation_timer', 'immunity', 'immunity_timer' ] )
        csv_writer.writerows( rows )

if __name__ == "__main__":
    
    settings.pop_file_out=f"pop_{int(settings.pop)}_{settings.num_nodes}nodes_seeded.csv"

    create_pop_csv()
