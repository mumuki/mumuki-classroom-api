require_relative './spec_helper'

describe Mumuki::Classroom::Reports::Formats do
  let(:stats) {
    [{name: 'john', surname: 'doe', age: 23},
     {name: 'dorothy', surname: 'doe', age: 22}]
  }

  let(:report) { Mumuki::Classroom::Reports::Formats.format_report(format, stats) }

  describe Mumuki::Classroom::Reports::Formats::Json do
    let(:format) { 'json' }
    it { expect(report).to eq stats.to_json }
  end
  describe Mumuki::Classroom::Reports::Formats::Csv do
    let(:format) { 'csv' }
    it { expect(report).to eq "john,doe,23\ndorothy,doe,22\n" }
  end
  describe Mumuki::Classroom::Reports::Formats::Table do
    let(:format) { 'table' }
    it { expect(report).to include "name | surname | age\n" }
    it { expect(report).to include "--------------------\n" }
    it { expect(report).to include "john | doe | 23\n" }
    it { expect(report).to include "dorothy | doe | 22\n" }
  end
end
