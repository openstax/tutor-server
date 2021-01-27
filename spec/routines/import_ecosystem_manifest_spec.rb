require 'rails_helper'
require 'vcr_helper'

RSpec.describe ImportEcosystemManifest, type: :routine, vcr: VCR_OPTS do
  let(:expected_exercise_uids_set) {
    Set.new expected_exercise_numbers.each_with_index.map do |number, index|
      version = expected_exercise_versions[index]
      "#{number}@#{version}"
    end
  }

  let(:fixture_path)                   { 'spec/fixtures/content/sample_manifest.yml' }
  let(:expected_ecosystem_title_start) { 'Physics (93e2b09d-261c-4007-a987-0b3062fe154b@4.4)' }
  let(:expected_book_cnx_id)           { '93e2b09d-261c-4007-a987-0b3062fe154b@4.4' }

  let(:expected_exercise_numbers)      {
    [
      1982, 1983, 1984, 1985, 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994, 1995, 1996,
      1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011,
      2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026,
      2027, 2028, 2029, 2030, 2031, 2032, 2033, 2034, 2035, 2036, 2037, 2038, 2039, 2040, 2041,
      2042, 2043, 2044, 2045, 2046, 2047, 2048, 2049, 2050, 2051, 2052, 2053, 2054, 2055, 2056,
      2057, 2058, 2059, 2060, 2061, 2062, 2063, 2064, 2065, 2066, 2067, 2068, 2069, 2070, 2071,
      2072, 2073, 2074, 2075, 2076, 2077, 2078, 2079, 2080, 2081, 2082, 2083, 2084, 2085, 2086,
      2087, 2088, 2089, 2090, 2091, 2092, 2093, 2094, 2095, 2096, 2097, 2098, 2099, 2100, 2101,
      2102, 2103, 2104, 2105, 2106, 2107, 2108, 2109, 2110, 2111, 2112, 2113, 2114, 2115, 2116,
      2117, 2118, 2119, 2120, 2121, 2122, 2123, 2124, 2125, 2126, 2127, 2128, 2129, 2130, 2131,
      2132, 2133, 2134, 2135, 2136, 2137, 2138, 2139, 2140, 2141, 2142, 2143, 2144, 2145, 2146,
      2147, 2148, 2149, 2150, 2151, 2152, 2153, 2154, 2155, 2156, 2157, 2158, 2159, 2160, 2161,
      2162, 2163, 2164, 2165, 2166, 2167, 2168, 2169, 2170, 2171, 2172, 2173, 2174, 2175, 2176,
      2177, 2178, 2179, 2180, 2181, 2182, 2183, 2184, 2185, 2186, 2187, 2188, 2189, 2190, 2191,
      2192, 2193, 2194, 2195, 2196
    ]
  }
  let(:expected_exercise_versions)     {
    [
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 353, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 530, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 17, 126, 17, 15, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1
    ]
  }

  let(:expected_manifest_hash) { YAML.load(manifest_yaml).deep_symbolize_keys }
  let(:expected_book_hash)     { expected_manifest_hash[:books].first }

  let(:manifest_yaml) { File.read fixture_path }

  before do
    expect(Content::UploadEcosystemManifestToValidator).to receive(:perform_later) do |manifest|
      manifest_hash = YAML.load(manifest).deep_symbolize_keys
      book_hash = manifest_hash[:books].first

      expect(manifest_hash.except(:title, :books)).to(
        eq expected_manifest_hash.except(:title, :books)
      )
      expect(expected_manifest_hash[:title]).to include manifest_hash[:title]
      expect(book_hash.except(:archive_url)).to eq expected_book_hash.except(:archive_url)
      expect(book_hash[:archive_url]).to eq expected_book_hash[:archive_url]
    end
  end

  it 'can import an ecosystem from a manifest' do
    manifest = Content::Manifest.from_yaml(manifest_yaml)

    expect { @new_ecosystem = described_class[manifest: manifest] }.to(
      change { Content::Models::Ecosystem.count }.by(1)
    )

    expect(@new_ecosystem.title).to start_with expected_ecosystem_title_start
    expect(@new_ecosystem.books.first.cnx_id).to eq expected_book_cnx_id
    expect(Set.new @new_ecosystem.exercises.map(&:uid)).to eq expected_exercise_uids_set
  end
end
