require 'rails_helper'

RSpec.describe Content::Manifest do
  let(:fixture_path)          { 'spec/fixtures/content/sample_manifest.yml' }
  let(:manifest_yaml)         { File.open(fixture_path) { |file| file.read } }
  let(:manifest)              { described_class.from_yaml(manifest_yaml) }
  let(:expected_exercise_ids) {
    [
      '1982@1', '1983@1', '1984@1', '1985@1', '1986@1', '1987@1', '1988@1', '1989@1',
      '1990@1', '1991@1', '1992@1', '1993@1', '1994@1', '1995@1', '1996@1', '1997@1',
      '1998@1', '1999@1', '2000@1', '2001@1', '2002@1', '2003@1', '2004@1', '2005@1',
      '2006@1', '2007@1', '2008@1', '2009@1', '2010@1', '2011@1', '2012@1', '2013@1',
      '2014@1', '2015@1', '2016@1', '2017@1', '2018@1', '2019@1', '2020@353', '2021@1',
      '2022@1', '2023@1', '2024@1', '2025@1', '2026@1', '2027@1', '2028@1', '2029@1',
      '2030@1', '2031@1', '2032@1', '2033@1', '2034@1', '2035@1', '2036@1', '2037@1',
      '2038@1', '2039@1', '2040@2', '2041@1', '2042@1', '2043@1', '2044@1', '2045@1',
      '2046@1', '2047@1', '2048@1', '2049@1', '2050@1', '2051@1', '2052@1', '2053@1',
      '2054@1', '2055@1', '2056@1', '2057@1', '2058@1', '2059@1', '2060@1', '2061@1',
      '2062@1', '2063@1', '2064@1', '2065@1', '2066@1', '2067@1', '2068@1', '2069@1',
      '2070@1', '2071@1', '2072@1', '2073@1', '2074@1', '2075@1', '2076@1', '2077@1',
      '2078@1', '2079@1', '2080@1', '2081@1', '2082@1', '2083@1', '2084@1', '2085@1',
      '2086@1', '2087@1', '2088@1', '2089@1', '2090@1', '2091@1', '2092@1', '2093@1',
      '2094@1', '2095@1', '2096@1', '2097@1', '2098@1', '2099@1', '2100@1', '2101@1',
      '2102@1', '2103@1', '2104@1', '2105@1', '2106@1', '2107@1', '2108@1', '2109@1',
      '2110@1', '2111@1', '2112@1', '2113@1', '2114@1', '2115@1', '2116@1', '2117@1',
      '2118@1', '2119@1', '2120@530', '2121@1', '2122@1', '2123@1', '2124@1', '2125@1',
      '2126@1', '2127@1', '2128@1', '2129@1', '2130@1', '2131@1', '2132@1', '2133@1',
      '2134@1', '2135@1', '2136@1', '2137@17', '2138@126', '2139@17', '2140@15', '2141@1',
      '2142@1', '2143@1', '2144@1', '2145@1', '2146@1', '2147@1', '2148@1', '2149@1',
      '2150@1', '2151@1', '2152@1', '2153@1', '2154@1', '2155@1', '2156@1', '2157@1',
      '2158@1', '2159@1', '2160@1', '2161@1', '2162@1', '2163@1', '2164@1', '2165@1',
      '2166@1', '2167@1', '2168@1', '2169@1', '2170@1', '2171@1', '2172@1', '2173@1',
      '2174@1', '2175@1', '2176@1', '2177@1', '2178@1', '2179@1', '2180@1', '2181@1',
      '2182@1', '2183@1', '2184@1', '2185@1', '2186@1', '2187@1', '2188@1', '2189@1',
      '2190@1', '2191@1', '2192@1', '2193@1', '2194@1', '2195@1', '2196@1'
    ]
  }
  let(:expected_reading_processing_instructions) {
    [
      { css: '.ost-reading-discard, .os-teacher, [data-type="glossary"]',
        fragments: [], except: 'snap-lab' },
      { css: '.ost-feature:has-descendants(".os-exercise",2), ' +
             '.ost-feature:has-descendants(".ost-exercise-choice"), ' +
             '.ost-assessed-feature:has-descendants(".os-exercise",2), ' +
             '.ost-assessed-feature:has-descendants(".ost-exercise-choice")',
        fragments: ['node', 'optional_exercise'] },
      { css: '.ost-feature:has-descendants(".os-exercise, .ost-exercise-choice"), ' +
             '.ost-assessed-feature:has-descendants(".os-exercise, .ost-exercise-choice")',
        fragments: ['node', 'exercise'] },
      { css: '.ost-feature .ost-exercise-choice, .ost-assessed-feature .ost-exercise-choice, ' +
             '.ost-feature .os-exercise, .ost-assessed-feature .os-exercise', fragments: [] },
      { css: '.ost-exercise-choice', fragments: ['exercise', 'optional_exercise'] },
      { css: '.os-exercise', fragments: ['exercise'] },
      { css: '.ost-video', fragments: ['video'] },
      { css: '.os-interactive, .ost-interactive', fragments: ['interactive'] },
      { css: '.worked-example', fragments: ['reading'], labels: ['worked-example'] },
      { css: '.ost-feature, .ost-assessed-feature', fragments: ['reading'] }
    ]
  }

  it 'can return ecosystem attributes' do
    expect(manifest.valid?).to eq true
    expect(manifest.title).to(
      start_with 'Physics (93e2b09d-261c-4007-a987-0b3062fe154b@4.4)'
    )
    book = manifest.books.first
    expect(book.archive_url).to eq 'https://archive-staging-tutor.cnx.org/'
    expect(book.cnx_id).to eq '93e2b09d-261c-4007-a987-0b3062fe154b@4.4'
    book.reading_processing_instructions.each_with_index do |processing_instruction, index|
      expected_processing_instruction = expected_reading_processing_instructions[index]
      expect(processing_instruction['css']).to eq expected_processing_instruction[:css]
      expect(processing_instruction['fragments']).to(
        eq expected_processing_instruction[:fragments]
      )
      expect(processing_instruction['except']).to eq expected_processing_instruction[:except]
      expect(processing_instruction['labels']).to eq expected_processing_instruction[:labels]
    end
    expect(book.exercise_ids).to eq expected_exercise_ids
  end

  it 'can be serialized back into a yaml file' do
    expect(manifest.to_yaml).to eq manifest_yaml
  end
end
